# annual laporan endpoints dan helpers (pdf, excel)

import os
import re
import json
from datetime import datetime
from io import BytesIO
from copy import copy
from collections import OrderedDict
from flask import jsonify, send_file, current_app, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from openpyxl import load_workbook
from openpyxl.cell.cell import MergedCell
from openpyxl.styles import Font, Alignment, PatternFill
from reportlab.lib.pagesizes import letter, landscape
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from sqlalchemy import text as sql_text

from models import User, Expense, Category, Settlement, ManualCombineGroup, db
from . import reports_bp
from .helpers import (
    _default_report_year, _safe_set_cell, _safe_set_number,
    _normalize_external_formula_refs, _clear_range, _clear_data_keep_formulas,
    _set_rows_hidden, _safe_text, _extract_imported_row, _extract_imported_sheet_row,
    _is_template_detail_data_row, _map_expense_category_index_from_name,
    _pick_template_formula_col, _get_expense_blocks, _parse_iso_date,
    _to_float, _as_iso_date, _idr_from_currency, _shorten, _map_expense_column,
    _is_batch_settlement, _clean_settlement_title, _group_annual_expenses,
)


PARENT_CATEGORY_NAMES = {
    'biaya operasi',
    'biaya research (r&d)',
    'biaya sewa peralatan',
    'biaya interpretasi log data',
    'administrasi',
    'pembelian barang',
    'sewa kantor',
    'kesehatan',
    'bisnis dev',
}




def _extract_subcategory_from_description(description):
    """Ekstrak sub-kategori dari deskripsi dengan format [SubCategory] Description"""
    if not description:
        return ''
    match = re.match(r'^\[(.*?)\]\s*', description.strip())
    if match:
        return match.group(1).strip()
    return ''


def _root_category_info(category_id, category_by_id):
    cat = category_by_id.get(category_id)
    if not cat: return '-', '-'
    subcategory_name = cat.name
    while cat.parent_id and category_by_id.get(cat.parent_id):
        cat = category_by_id[cat.parent_id]
    return cat.name or '-', subcategory_name or '-'


def _subcategory_sort_key(label):
    text = _safe_text(label).strip()
    if not text or text == '-':
        return (1, '')
    return (0, text.lower())


def _write_dynamic_category_headers(ws, root_cats, header_row=40, start_col=9, template_end_col=17):
    last_used_col = max(template_end_col, start_col + len(root_cats) - 1)
    for col in range(start_col, last_used_col + 1):
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        if col >= start_col + len(root_cats):
            cell.value = None

    for offset, category in enumerate(root_cats):
        col = start_col + offset
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        cell.value = category.name
        alignment = copy(cell.alignment)
        alignment.wrap_text = True
        alignment.horizontal = 'center'
        alignment.vertical = 'center'
        cell.alignment = alignment


def _clone_row_format(ws, source_row, target_row, start_col=1, end_col=17):
    ws.row_dimensions[target_row].height = ws.row_dimensions[source_row].height
    for col in range(start_col, end_col + 1):
        source_cell = ws.cell(row=source_row, column=col)
        target_cell = ws.cell(row=target_row, column=col)
        if isinstance(source_cell, MergedCell) or isinstance(target_cell, MergedCell):
            continue
        target_cell._style = copy(source_cell._style)
        target_cell.number_format = source_cell.number_format
        target_cell.font = copy(source_cell.font)
        target_cell.fill = copy(source_cell.fill)
        target_cell.border = copy(source_cell.border)
        target_cell.alignment = copy(source_cell.alignment)
        target_cell.protection = copy(source_cell.protection)
        target_cell.value = None


def _is_true(value):
    if value is None:
        return False
    return str(value).strip().lower() in ('1', 'true', 'yes', 'y')


def _annual_cache_paths(year):
    cache_dir = os.path.abspath(
        os.path.join(current_app.root_path, '..', 'exports', 'annual_cache')
    )
    os.makedirs(cache_dir, exist_ok=True)
    return {
        'json': os.path.join(cache_dir, f'annual_{year}.json'),
        'pdf': os.path.join(cache_dir, f'annual_{year}.pdf'),
    }


def _load_annual_payload_cache(year):
    json_path = _annual_cache_paths(year)['json']
    if not os.path.exists(json_path):
        return None
    with open(json_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def _save_annual_payload_cache(year, payload):
    data = dict(payload)
    data['cache_generated_at'] = datetime.now().isoformat()
    json_path = _annual_cache_paths(year)['json']
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return data


def _save_annual_pdf_cache(year, pdf_bytes):
    pdf_path = _annual_cache_paths(year)['pdf']
    with open(pdf_path, 'wb') as f:
        f.write(pdf_bytes)
    return pdf_path


def _tagged_ids_for_year(table_name, report_year):
    try:
        rows = db.session.execute(
            sql_text("""SELECT row_id FROM report_entry_tags
                WHERE table_name = :table_name AND report_year = :report_year"""),
            {'table_name': table_name, 'report_year': int(report_year)},
        ).fetchall()
        return [int(r[0]) for r in rows]
    except Exception:
        return []


def _has_any_report_tags():
    try:
        row = db.session.execute(sql_text("SELECT 1 FROM report_entry_tags LIMIT 1")).first()
        return row is not None
    except Exception:
        return False


def _compute_dividend_distribution(revenues, expenses, profit_retained, recipient_count):
    revenue_total = sum((r.idr_amount_received or 0) for r in revenues)
    pph23_total = sum((r.pph_23 or 0) for r in revenues)
    total_cost = sum((e.idr_amount or 0) for e in expenses)
    profit_before_tax = revenue_total - total_cost
    tax_corporate = profit_before_tax * 0.22 * 0.5 if profit_before_tax > 0 else 0.0
    profit_after_tax = profit_before_tax - (tax_corporate - pph23_total)
    dividend_distributed = max(profit_after_tax - profit_retained, 0.0)
    dividend_per_person = (
        dividend_distributed / recipient_count if recipient_count > 0 else 0.0
    )
    return {
        'revenue_total': revenue_total,
        'pph23_total': pph23_total,
        'total_cost': total_cost,
        'profit_before_tax': profit_before_tax,
        'tax_corporate': tax_corporate,
        'profit_after_tax': profit_after_tax,
        'profit_retained': profit_retained,
        'dividend_distributed': dividend_distributed,
        'dividend_per_person': dividend_per_person,
    }

def _build_annual_payload_from_db(year):
    from models import Dividend, DividendSetting, Revenue, Tax
    has_report_tags = _has_any_report_tags()
    tagged_revenue_ids = _tagged_ids_for_year('revenues', year)
    tagged_tax_ids = _tagged_ids_for_year('taxes', year)
    if has_report_tags:
        if tagged_revenue_ids:
            revenues_raw = Revenue.query.filter(Revenue.id.in_(tagged_revenue_ids)).all()
            # Meskipun ada tags, tetap urutkan berdasarkan tanggal invoice agar logis
            revenues = sorted(revenues_raw, key=lambda r: (r.invoice_date or datetime.min.date(), r.id))
        else:
            revenues = []
    elif tagged_revenue_ids:
        revenues = Revenue.query.filter(Revenue.id.in_(tagged_revenue_ids)).order_by(Revenue.invoice_date.asc(), Revenue.id.asc()).all()
    else:
        revenues = Revenue.query.filter(db.extract('year', Revenue.invoice_date) == year).order_by(Revenue.invoice_date.asc(), Revenue.id.asc()).all()

    if has_report_tags:
        if tagged_tax_ids:
            taxes = Tax.query.filter(Tax.id.in_(tagged_tax_ids)).all()
            tax_order = {tid: idx for idx, tid in enumerate(tagged_tax_ids)}
            taxes.sort(key=lambda t: tax_order.get(t.id, 10**9))
        else:
            taxes = []
    elif tagged_tax_ids:
        taxes = Tax.query.filter(Tax.id.in_(tagged_tax_ids)).order_by(Tax.date.asc()).all()
    else:
        tax_years = [year]
        if year == 2024: tax_years.append(2023)
        taxes = Tax.query.filter(db.extract('year', Tax.date).in_(tax_years)).order_by(Tax.date.asc(), Tax.id.asc()).all()

    expenses_query = Expense.query.join(
        Settlement, Expense.settlement_id == Settlement.id
    ).filter(
        Settlement.status.in_(('approved', 'completed')),
        db.extract('year', Expense.date) == year,
    )
    expenses = expenses_query.order_by(Expense.date.asc()).all()
    dividends = Dividend.query.filter(
        db.extract('year', Dividend.date) == year,
    ).order_by(Dividend.date.asc(), Dividend.id.asc()).all()
    dividend_setting = DividendSetting.query.filter_by(year=year).first()

    revenue_data = [r.to_dict() for r in revenues]
    tax_data = [t.to_dict() for t in taxes]
    dividend_calc = _compute_dividend_distribution(
        revenues,
        expenses,
        dividend_setting.profit_retained if dividend_setting else 0.0,
        len(dividends),
    )
    dividend_data = []
    for d in dividends:
        row = d.to_dict()
        row['dividend_per_person'] = dividend_calc['dividend_per_person']
        dividend_data.append(row)

    all_categories = Category.query.all()
    category_by_id = {c.id: c for c in all_categories}
    expense_data = []
    for e in expenses:
        d = e.to_dict()
        root_name, subcat_name = _root_category_info(e.category_id, category_by_id)
        d['category_name'] = root_name
        d['subcategory_name'] = subcat_name
        d['settlement_id'] = e.settlement_id
        d['settlement_title'] = _clean_settlement_title(e.settlement.title if e.settlement else '-')
        d['settlement_type'] = e.settlement.settlement_type if e.settlement else 'single'
        d['settlement_description'] = e.settlement.description if e.settlement else ''
        expense_data.append(d)
    ordered_expense_data = []
    for group in _group_annual_expenses(expense_data, year):
        ordered_expense_data.extend(group)
    return {
        'year': year,
        'revenue': {'data': revenue_data, 'total_amount_received': sum(r.idr_amount_received for r in revenues),
                    'total_ppn': sum(r.ppn or 0 for r in revenues), 'total_pph23': sum(r.pph_23 or 0 for r in revenues)},
        'tax': {'data': tax_data, 'total_ppn': sum(t.ppn or 0 for t in taxes), 'total_pph21': sum(t.pph_21 or 0 for t in taxes),
                'total_pph23': sum(t.pph_23 or 0 for t in taxes), 'total_pph26': sum(t.pph_26 or 0 for t in taxes)},
        'dividend': {
            'data': dividend_data,
            'profit_after_tax': dividend_calc['profit_after_tax'],
            'profit_retained': dividend_calc['profit_retained'],
            'total_amount': dividend_calc['dividend_distributed'],
            'total_recipient_count': len(dividends),
            'dividend_per_person': dividend_calc['dividend_per_person'],
            'settings': dividend_setting.to_dict() if dividend_setting else {
                'year': year,
                'profit_retained': 0.0,
                'opening_cash_balance': 0.0,
                'accounts_receivable': 0.0,
                'prepaid_tax_pph23': 0.0,
                'prepaid_expenses': 0.0,
                'other_receivables': 0.0,
                'office_inventory': 0.0,
                'other_assets': 0.0,
                'accounts_payable': 0.0,
                'salary_payable': 0.0,
                'shareholder_payable': 0.0,
                'accrued_expenses': 0.0,
                'share_capital': 0.0,
                'retained_earnings_balance': 0.0,
            },
        },
        'operation_cost': {'data': ordered_expense_data, 'total_expenses': sum((e.idr_amount or 0) for e in expenses)},
        'generated_at': datetime.now().isoformat(),
    }

def _build_annual_pdf_bytes(payload):
    year = payload.get('year', datetime.now().year)
    revenues = payload.get('revenue', {}).get('data', [])
    taxes = payload.get('tax', {}).get('data', [])
    dividends = payload.get('dividend', {}).get('data', [])
    expenses = payload.get('operation_cost', {}).get('data', [])
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=landscape(letter), rightMargin=20, leftMargin=20, topMargin=20, bottomMargin=20)
    elements = []; styles = getSampleStyleSheet()
    title_style = ParagraphStyle('Title', parent=styles['Heading1'], alignment=0, fontSize=14)
    elements.append(Paragraph(f"Project: REVENUE vs OPERATION COST Tahun {year}", title_style))
    elements.append(Paragraph(f"Date: Januari - Desember {year}", styles['Normal']))
    elements.append(Spacer(1, 15))
    # tabel revenue & tax
    elements.append(Paragraph("REVENUE & TAX", styles['Heading3']))
    t1_headers = ['Invoice Date','#','Detail/Description','INVOICE VALUE','Curr','Rate','INVOICE Num','Client','Receive Date','AMT RECEIVED','PPn','PPH 23','TransferFee','Remark']
    t1_data = [t1_headers]; total_inv_value = 0; total_received = 0; total_ppn = 0; total_pph = 0
    for idx, r in enumerate(revenues, 1):
        inv_val = _idr_from_currency(r.get('invoice_value'), r.get('currency'), r.get('currency_exchange'))
        amt_rec = _idr_from_currency(r.get('amount_received'), r.get('currency'), r.get('currency_exchange'))
        ppn = _to_float(r.get('ppn')); pph23 = _to_float(r.get('pph_23')); transfer = _to_float(r.get('transfer_fee'))
        total_inv_value += inv_val; total_received += amt_rec; total_ppn += ppn; total_pph += pph23
        t1_data.append([_as_iso_date(r.get('invoice_date')),str(idx),_shorten(r.get('description'),30),
            f"{inv_val:,.0f}" if inv_val else '-',_safe_text(r.get('currency')) or 'IDR',
            f"{_to_float(r.get('currency_exchange'),1):,.0f}" if r.get('currency_exchange') else '-',
            _safe_text(r.get('invoice_number')),_safe_text(r.get('client')),_as_iso_date(r.get('receive_date')),
            f"{amt_rec:,.0f}" if amt_rec else '-',f"{ppn:,.0f}" if ppn else '-',f"{pph23:,.0f}" if pph23 else '-',
            f"{transfer:,.0f}" if transfer else '-',_safe_text(r.get('remark'))])
    t1_data.append(["REVENUE (IDR)","","",f"{total_inv_value:,.0f}","","","","","",f"{total_received:,.0f}",f"{total_ppn:,.0f}",f"{total_pph:,.0f}","-","-"])
    t1 = Table(t1_data, colWidths=[60,20,120,70,30,35,60,60,60,70,50,50,50,50])
    t1.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#2E7D32')),('TEXTCOLOR',(0,0),(-1,0),colors.whitesmoke),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTSIZE',(0,0),(-1,-1),7),('ALIGN',(3,1),(5,-1),'RIGHT'),
        ('ALIGN',(9,1),(12,-1),'RIGHT'),('GRID',(0,0),(-1,-1),0.5,colors.grey),
        ('BACKGROUND',(0,-1),(-1,-1),colors.HexColor('#E8F5E9')),('FONTNAME',(0,-1),(-1,-1),'Helvetica-Bold')]))
    elements.append(t1); elements.append(Spacer(1, 15))
    # tabel tax
    elements.append(Paragraph("PAJAK PENGELUARAN", styles['Heading3']))
    t2_headers = ['Date','#','Detail/Description','Trans Value','Curr','Rate','PPN','PPh 21','PPh 23','PPh 26']
    t2_data = [t2_headers]; sum_ppn = 0; sum_pph21 = 0; sum_pph23 = 0; sum_pph26 = 0
    for idx, t in enumerate(taxes, 1):
        ppn = _to_float(t.get('ppn')); pph21 = _to_float(t.get('pph_21')); pph23 = _to_float(t.get('pph_23')); pph26 = _to_float(t.get('pph_26'))
        trans_val = _idr_from_currency(t.get('transaction_value'), t.get('currency'), t.get('currency_exchange'))
        sum_ppn += ppn; sum_pph21 += pph21; sum_pph23 += pph23; sum_pph26 += pph26
        t2_data.append([_as_iso_date(t.get('date')),str(idx),_shorten(t.get('description'),40),
            f"{trans_val:,.0f}" if trans_val else '-',_safe_text(t.get('currency')) or 'IDR',
            f"{_to_float(t.get('currency_exchange'),1):,.0f}" if t.get('currency_exchange') else '-',
            f"{ppn:,.0f}" if ppn else '-',f"{pph21:,.0f}" if pph21 else '-',f"{pph23:,.0f}" if pph23 else '-',f"{pph26:,.0f}" if pph26 else '-'])
    t2_data.append(["PENERIMAAN NEGARA","","","","","",f"{sum_ppn:,.0f}",f"{sum_pph21:,.0f}",f"{sum_pph23:,.0f}",f"{sum_pph26:,.0f}"])
    t2 = Table(t2_data, colWidths=[60,20,180,70,30,35,60,60,60,60])
    t2.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#D84315')),('TEXTCOLOR',(0,0),(-1,0),colors.whitesmoke),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTSIZE',(0,0),(-1,-1),7),('ALIGN',(3,1),(-1,-1),'RIGHT'),
        ('GRID',(0,0),(-1,-1),0.5,colors.grey),('BACKGROUND',(0,-1),(-1,-1),colors.HexColor('#FBE9E7')),('FONTNAME',(0,-1),(-1,-1),'Helvetica-Bold')]))
    elements.append(t2); elements.append(Spacer(1, 15))
    if dividends:
        elements.append(Paragraph("DIVIDEN", styles['Heading3']))
        t_div_headers = ['Date', '#', 'Nama Penerima', 'Profit Ditahan', 'Dividen Dibagi', 'Dibagi/Orang']
        t_div_data = [t_div_headers]
        total_dividend = _to_float(payload.get('dividend', {}).get('total_amount'))
        profit_retained = _to_float(payload.get('dividend', {}).get('profit_retained'))
        dividend_per_person = _to_float(payload.get('dividend', {}).get('dividend_per_person'))
        for idx, item in enumerate(dividends, 1):
            t_div_data.append([
                _as_iso_date(item.get('date')),
                str(idx),
                _safe_text(item.get('name')),
                f"{profit_retained:,.0f}" if profit_retained else '-',
                f"{total_dividend:,.0f}" if total_dividend else '-',
                f"{dividend_per_person:,.0f}" if dividend_per_person else '-',
            ])
        t_div_data.append([
            'TOTAL',
            '',
            '',
            f"{profit_retained:,.0f}" if profit_retained else '-',
            f"{total_dividend:,.0f}" if total_dividend else '-',
            f"{dividend_per_person:,.0f}" if dividend_per_person else '-',
        ])
        t_div = Table(t_div_data, colWidths=[60, 20, 180, 90, 90, 90])
        t_div.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#6A1B9A')),('TEXTCOLOR',(0,0),(-1,0),colors.whitesmoke),
            ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTSIZE',(0,0),(-1,-1),7),('ALIGN',(3,1),(-1,-1),'RIGHT'),
            ('GRID',(0,0),(-1,-1),0.5,colors.grey),('BACKGROUND',(0,-1),(-1,-1),colors.HexColor('#F3E5F5')),('FONTNAME',(0,-1),(-1,-1),'Helvetica-Bold')]))
        elements.append(t_div); elements.append(Spacer(1, 15))
    # tabel expense
    elements.append(Paragraph("PENGELUARAN & OPERATION COST", styles['Heading3']))
    # Fetch root categories dynamically from DB
    root_cats = Category.query.filter_by(parent_id=None).order_by(Category.id).all()
    cat_columns = [c.name for c in root_cats]
    cat_names = cat_columns # for mapping

    t3_headers = ['Date','#','Activity (Desc)','Source','Jumlah (IDR)','Curr','Rate'] + [c[:10]+'.' for c in cat_columns]
    t3_data = [t3_headers]; cat_totals = [0]*len(cat_columns); grand_total = 0
    for idx, e in enumerate(expenses, 1):
        nominal_idr = _to_float(e.get('idr_amount'))
        if nominal_idr == 0: nominal_idr = _idr_from_currency(e.get('amount'), e.get('currency'), e.get('currency_exchange'))
        col_idx = _map_expense_column(e.get('category_name'), cat_names)
        row_cats = ['-']*len(cat_columns); row_cats[col_idx] = f"{nominal_idr:,.0f}" if nominal_idr else '-'
        cat_totals[col_idx] += nominal_idr; grand_total += nominal_idr
        t3_data.append([_as_iso_date(e.get('date')),str(idx),_shorten(e.get('description'),30),_shorten(e.get('source'),10),
            f"{nominal_idr:,.0f}" if nominal_idr else '-',_safe_text(e.get('currency')) or 'IDR',
            f"{_to_float(e.get('currency_exchange'),1):,.0f}" if e.get('currency_exchange') else '-'] + row_cats)
    t3_data.append(["TOTAL PENGELUARAN","","","",f"{grand_total:,.0f}","",""] + [f"{t:,.0f}" if t > 0 else "-" for t in cat_totals])
    cw = [55,20,110,50,60,25,25] + [45]*len(cat_columns)
    t3 = Table(t3_data, colWidths=cw)
    t3.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#1565C0')),('TEXTCOLOR',(0,0),(-1,0),colors.whitesmoke),
        ('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTSIZE',(0,0),(-1,-1),6),('ALIGN',(4,1),(-1,-1),'RIGHT'),
        ('GRID',(0,0),(-1,-1),0.5,colors.grey),('BACKGROUND',(0,-1),(-1,-1),colors.HexColor('#E3F2FD')),('FONTNAME',(0,-1),(-1,-1),'Helvetica-Bold')]))
    elements.append(t3); elements.append(Spacer(1, 14))
    elements.append(Paragraph("AREA DISPLAY / IMPORT (Kosong - diisi saat refresh)", styles['Heading3']))
    area_data = [['No','Keterangan','Nilai']]
    for idx in range(1, 6): area_data.append([str(idx),'',''])
    area_table = Table(area_data, colWidths=[30,410,180], rowHeights=[18]+[24]*5)
    area_table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#ECEFF1')),('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),
        ('GRID',(0,0),(-1,-1),0.5,colors.grey),('VALIGN',(0,0),(-1,-1),'MIDDLE')]))
    elements.append(area_table)
    doc.build(elements); buffer.seek(0)
    return buffer.read()

def _sheet_ref(name: str) -> str:
    return f"'{name}'" if " " in name or "-" in name else name


def _write_secondary_summary_sheets(wb, payload, year, main_sheet_name):
    revenues = payload.get('revenue', {}).get('data', [])
    taxes = payload.get('tax', {}).get('data', [])
    expenses = payload.get('operation_cost', {}).get('data', [])
    monthly = {m: {'revenue': 0.0, 'tax': 0.0, 'expense': 0.0} for m in range(1, 13)}
    for r in revenues:
        dtv = _parse_iso_date(r.get('invoice_date'))
        if not dtv: continue
        monthly[dtv.month]['revenue'] += _idr_from_currency(r.get('amount_received'), r.get('currency'), r.get('currency_exchange'))
    for t in taxes:
        dtv = _parse_iso_date(t.get('date'))
        if not dtv: continue
        monthly[dtv.month]['tax'] += _to_float(t.get('ppn')) + _to_float(t.get('pph_21')) + _to_float(t.get('pph_23')) + _to_float(t.get('pph_26'))
    for e in expenses:
        dtv = _parse_iso_date(e.get('date'))
        if not dtv: continue
        monthly[dtv.month]['expense'] += _expense_amount_for_display(e)
    def _get_or_create(name):
        if name in wb.sheetnames:
            ws = wb[name]; ws.delete_rows(1, ws.max_row or 1); return ws
        return wb.create_sheet(name)
    header_fill = PatternFill(start_color='D9EAD3', end_color='D9EAD3', fill_type='solid')
    month_labels = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des']
    main_ref = _sheet_ref(main_sheet_name)
    # sheet 2: laba rugi
    ws_lr = _get_or_create(f'Laba rugi -{year}')
    ws_lr['A1'] = f'Laba Rugi Tahun {year}'; ws_lr['A1'].font = Font(bold=True, size=14); ws_lr.merge_cells('A1:E1')
    ws_lr['A3'] = 'Bulan'; ws_lr['B3'] = 'Revenue (IDR)'; ws_lr['C3'] = 'Tax Out (IDR)'; ws_lr['D3'] = 'Operation Cost (IDR)'; ws_lr['E3'] = 'Laba/Rugi (IDR)'
    for c in 'ABCDE':
        cell = ws_lr[f'{c}3']; cell.font = Font(bold=True); cell.fill = header_fill; cell.alignment = Alignment(horizontal='center')
    row = 4
    for m in range(1, 13):
        ws_lr.cell(row=row, column=1, value=month_labels[m-1])
        ws_lr.cell(row=row, column=2, value=monthly[m]['revenue'])
        ws_lr.cell(row=row, column=3, value=monthly[m]['tax'])
        ws_lr.cell(row=row, column=4, value=monthly[m]['expense'])
        ws_lr.cell(row=row, column=5, value=f'=B{row}-C{row}-D{row}')
        row += 1
    ws_lr.cell(row=row, column=1, value='TOTAL')
    for c in range(2, 6): ws_lr.cell(row=row, column=c, value=f'=SUM({chr(64+c)}4:{chr(64+c)}{row-1})')
    for c in range(1, 6): ws_lr.cell(row=row, column=c).font = Font(bold=True)
    for col, width in {'A':14,'B':22,'C':20,'D':24,'E':24}.items(): ws_lr.column_dimensions[col].width = width
    # sheet 3: business summary
    ws_bs = _get_or_create('Business Summary')
    ws_bs['A1'] = f'Business Summary {year}'; ws_bs['A1'].font = Font(bold=True, size=14); ws_bs.merge_cells('A1:D1')
    rows = [
        ('Total Revenue (IDR)', f'={main_ref}!F22'),
        ('Total Tax Out (IDR)', f'={main_ref}!N22'),
        ('Total Operation Cost (IDR)', f'=SUM({main_ref}!I750:Q750)'),
        ('Net Profit/Loss (IDR)', '=B4-B5-B6'),
    ]
    ws_bs['A3'] = 'Keterangan'; ws_bs['B3'] = 'Nilai'
    for c in 'AB':
        cell = ws_bs[f'{c}3']; cell.font = Font(bold=True); cell.fill = header_fill; cell.alignment = Alignment(horizontal='center')
    rr = 4
    for label, value in rows:
        ws_bs.cell(row=rr, column=1, value=label)
        ws_bs.cell(row=rr, column=2, value=value)
        rr += 1
    ws_bs['A9'] = 'Monthly Snapshot'; ws_bs['A9'].font = Font(bold=True)
    ws_bs['A10'] = 'Bulan'; ws_bs['B10'] = 'Revenue'; ws_bs['C10'] = 'Tax'; ws_bs['D10'] = 'Expense'; ws_bs['E10'] = 'Net'
    for c in 'ABCDE':
        cell = ws_bs[f'{c}10']; cell.font = Font(bold=True); cell.fill = header_fill; cell.alignment = Alignment(horizontal='center')
    rr = 11
    for m in range(1, 13):
        ws_bs.cell(row=rr, column=1, value=month_labels[m-1])
        ws_bs.cell(row=rr, column=2, value=monthly[m]['revenue'])
        ws_bs.cell(row=rr, column=3, value=monthly[m]['tax'])
        ws_bs.cell(row=rr, column=4, value=monthly[m]['expense'])
        ws_bs.cell(row=rr, column=5, value=monthly[m]['revenue'] - monthly[m]['tax'] - monthly[m]['expense'])
        rr += 1
    for col, width in {'A':36,'B':22,'C':20,'D':24,'E':20}.items(): ws_bs.column_dimensions[col].width = width


def _expense_column_mapping_name(expense):
    category_name = _safe_text(expense.get('category_name')).strip()
    if category_name:
        return category_name

    category_id = expense.get('category_id')
    if category_id is None:
        return ''

    category = Category.query.get(category_id)
    if not category:
        return ''

    while category.parent_id:
        parent = Category.query.get(category.parent_id)
        if not parent:
            break
        category = parent
    return _safe_text(category.name).strip()


def _expense_amount_for_display(expense):
    nominal_idr = _to_float(expense.get('idr_amount'))
    if nominal_idr != 0:
        return nominal_idr
    return _idr_from_currency(
        expense.get('amount'),
        expense.get('currency'),
        expense.get('currency_exchange'),
    )


def _expense_subcategory_label(expense):
    raw_desc = _safe_text(expense.get('description')).strip()
    prefixed = re.match(r'^\[(.*?)\]\s*(.*)$', raw_desc)
    if prefixed:
        prefix = _safe_text(prefixed.group(1)).strip()
        if prefix:
            return prefix

    notes = _safe_text(expense.get('notes')).strip()
    note_match = re.search(r'\bSubcategory:\s*([^|]+)', notes, flags=re.IGNORECASE)
    if note_match:
        note_subcategory = _safe_text(note_match.group(1)).strip()
        if note_subcategory:
            return note_subcategory

    desc = raw_desc.lower()
    if 'rental tool' in desc:
        return 'Rental Tool'
    if 'sales' in desc:
        return 'Sales'
    if 'gaji' in desc or 'bonus' in desc:
        return 'Gaji'
    if 'pembuatan alat' in desc or 'mesin retort' in desc:
        return 'Pembuatan Alat'
    if 'thr' in desc or 'allowance' in desc:
        return 'Allowance'
    if 'data processing' in desc:
        return 'Data Processing'
    if 'moving slickline' in desc or 'project lampu' in desc:
        return 'Project Operation'
    if 'sampling tool' in desc or 'sparepart' in desc or 'ups biaya import' in desc:
        return 'Sparepart'
    if 'repair esor' in desc:
        return 'Maintenance'
    if 'licence' in desc or 'license' in desc:
        return 'Software License'
    if 'handphone operational' in desc:
        return 'Operation'
    if 'sewa ruangan' in desc or 'virtual office' in desc:
        return 'Sewa Ruangan'
    if 'modal kerja' in desc:
        return 'Modal Kerja'
    if 'team building' in desc:
        return 'Team Building'
    if 'biaya transaksi bank' in desc:
        return 'Biaya Bank'

    subcategory_name = _safe_text(expense.get('subcategory_name')).strip()
    if subcategory_name:
        return subcategory_name
    return ''


def _fill_annual_expense_row(ws, row_num, expense, seq_num, cat_names, category_by_id_map):
    clean_desc = re.sub(r'^\[.*?\]\s*', '', (expense.get('description') or '').strip()).strip()
    _clear_range(ws, row_num, row_num, 2, 17)
    _safe_set_cell(ws, row_num, 2, _parse_iso_date(expense.get('date')))
    _safe_set_cell(ws, row_num, 3, seq_num)
    _safe_set_cell(ws, row_num, 4, clean_desc or '-')
    _safe_set_number(ws, row_num, 6, _expense_amount_for_display(expense))
    _safe_set_cell(ws, row_num, 7, expense.get('currency') or 'IDR')
    _safe_set_number(
        ws,
        row_num,
        8,
        _to_float(expense.get('currency_exchange'), default=1) or 1,
        number_format='0.########',
    )
    root_name, _ = _root_category_info(expense.get('category_id'), category_by_id_map)
    fallback_col = 9 + _map_expense_category_index_from_name(root_name, cat_names)
    _safe_set_number(ws, row_num, fallback_col, _expense_amount_for_display(expense))


def _render_batch_expense_block(
    ws,
    start_row,
    end_row,
    block_items,
    cat_names,
    category_by_id_map,
):
    detail_data_rows = [r for r in range(start_row, end_row + 1) if _is_template_detail_data_row(ws, r)]
    subcategory_rows = [
        r for r in range(start_row, end_row + 1)
        if (not _is_template_detail_data_row(ws, r)) and _safe_text(ws.cell(row=r, column=4).value).strip()
    ]
    if not detail_data_rows:
        return

    all_available_rows = sorted(set(detail_data_rows + subcategory_rows))
    header_template_row = subcategory_rows[0] if subcategory_rows else None
    detail_template_row = detail_data_rows[0] if detail_data_rows else None

    for row_num in all_available_rows:
        _clear_range(ws, row_num, row_num, 2, 17)
        _set_rows_hidden(ws, row_num, row_num, False)

    grouped_items = OrderedDict()
    for expense in sorted(
        block_items,
        key=lambda e: (
            _subcategory_sort_key(_expense_subcategory_label(e) or '-'),
            _extract_imported_row(e.get('notes')) is None,
            _extract_imported_row(e.get('notes')) or 10**9,
            int(e.get('id') or 0),
        ),
    ):
        label = (_expense_subcategory_label(expense) or '-').strip() or '-'
        key = label.lower()
        if key not in grouped_items:
            grouped_items[key] = {'label': label, 'items': []}
        grouped_items[key]['items'].append(expense)

    ordered_groups = sorted(
        grouped_items.values(),
        key=lambda entry: _subcategory_sort_key(entry['label']),
    )

    row_cursor = 0
    used_rows = set()
    fallback_seq = 1

    for group in ordered_groups:
        if row_cursor >= len(all_available_rows):
            break

        header_row = all_available_rows[row_cursor]
        if header_template_row is not None and header_row != header_template_row:
            _clone_row_format(ws, header_template_row, header_row)
        _clear_range(ws, header_row, header_row, 2, 17)
        _safe_set_cell(ws, header_row, 4, group['label'])
        ws.cell(row=header_row, column=4).font = Font(bold=True)
        _set_rows_hidden(ws, header_row, header_row, False)
        used_rows.add(header_row)
        row_cursor += 1

        for expense in group['items']:
            if row_cursor >= len(all_available_rows):
                break
            detail_row = all_available_rows[row_cursor]
            if detail_template_row is not None and detail_row != detail_template_row:
                _clone_row_format(ws, detail_template_row, detail_row)
            _fill_annual_expense_row(
                ws,
                detail_row,
                expense,
                fallback_seq,
                cat_names,
                category_by_id_map,
            )
            _set_rows_hidden(ws, detail_row, detail_row, False)
            used_rows.add(detail_row)
            row_cursor += 1
            fallback_seq += 1

    for row_num in all_available_rows:
        if row_num in used_rows:
            continue
        _clear_range(ws, row_num, row_num, 2, 17)
        _set_rows_hidden(ws, row_num, row_num, True)


def _manual_combine_groups_by_table(table_name, year):
    groups = ManualCombineGroup.query.filter_by(
        table_name=table_name,
        report_year=int(year),
    ).order_by(ManualCombineGroup.group_date.asc(), ManualCombineGroup.id.asc()).all()
    return [group.to_dict() for group in groups]


def _set_merged_top_alignment(ws, row_num, col_num):
    cell = ws.cell(row=row_num, column=col_num)
    alignment = copy(cell.alignment)
    alignment.horizontal = 'center'
    alignment.vertical = 'center'
    cell.alignment = alignment


def _clear_merged_ranges_in_region(ws, start_row, end_row, start_col, end_col):
    ranges_to_clear = []
    for merged_range in list(ws.merged_cells.ranges):
        min_col, min_row, max_col, max_row = merged_range.bounds
        overlaps = not (
            max_row < start_row or min_row > end_row or
            max_col < start_col or min_col > end_col
        )
        if overlaps:
            ranges_to_clear.append(str(merged_range))

    for merge_range in ranges_to_clear:
        try:
            ws.unmerge_cells(merge_range)
        except Exception:
            pass


def _apply_manual_revenue_combine_groups(ws, revenues, combine_groups, start_row=8):
    _clear_merged_ranges_in_region(ws, start_row, start_row + max(len(revenues) - 1, 0), 11, 12)
    if not revenues or not combine_groups:
        return

    row_by_id = {
        int(revenue.get('id') or 0): start_row + idx
        for idx, revenue in enumerate(revenues)
        if revenue.get('id') is not None
    }
    revenue_by_id = {
        int(revenue.get('id') or 0): revenue
        for revenue in revenues
        if revenue.get('id') is not None
    }

    for group in combine_groups:
        group_ids = [int(row_id) for row_id in group.get('row_ids', []) if int(row_id) in row_by_id]
        if len(group_ids) < 2:
            continue

        row_numbers = [row_by_id[row_id] for row_id in group_ids]
        row_start = min(row_numbers)
        row_end = max(row_numbers)
        if row_end <= row_start:
            continue

        total_received = 0.0
        group_date = None
        for row_id in group_ids:
            revenue = revenue_by_id.get(row_id, {})
            total_received += _idr_from_currency(
                revenue.get('amount_received'),
                revenue.get('currency'),
                revenue.get('currency_exchange'),
            )
            if group_date is None:
                group_date = _parse_iso_date(revenue.get('receive_date'))

        for merge_range in (f'K{row_start}:K{row_end}', f'L{row_start}:L{row_end}'):
            try:
                ws.unmerge_cells(merge_range)
            except Exception:
                pass
            ws.merge_cells(merge_range)

        _safe_set_cell(ws, row_start, 11, group_date)
        _safe_set_cell(ws, row_start, 12, total_received)
        _set_merged_top_alignment(ws, row_start, 11)
        _set_merged_top_alignment(ws, row_start, 12)


def _apply_manual_tax_combine_groups(ws, taxes, combine_groups, start_row=27):
    _clear_merged_ranges_in_region(ws, start_row, start_row + max(len(taxes) - 1, 0), 2, 16)
    if not taxes or not combine_groups:
        return

    row_by_id = {
        int(item.get('id') or 0): start_row + idx
        for idx, item in enumerate(taxes)
        if item.get('id') is not None
    }
    tax_by_id = {
        int(item.get('id') or 0): item
        for item in taxes
        if item.get('id') is not None
    }

    numeric_columns = {
        6: 'transaction_value',
        9: 'transaction_value',
        10: 'ppn',
        11: 'transaction_value',
        12: 'pph_21',
        13: 'transaction_value',
        14: 'pph_23',
        15: 'transaction_value',
        16: 'pph_26',
    }

    for group in combine_groups:
        group_ids = [int(row_id) for row_id in group.get('row_ids', []) if int(row_id) in row_by_id]
        if len(group_ids) < 2:
            continue

        row_numbers = [row_by_id[row_id] for row_id in group_ids]
        row_start = min(row_numbers)
        row_end = max(row_numbers)
        if row_end <= row_start:
            continue

        merged_date = None
        totals = {col: 0.0 for col in numeric_columns}
        for row_id in group_ids:
            item = tax_by_id.get(row_id, {})
            if merged_date is None:
                merged_date = _parse_iso_date(item.get('date'))
            for col_num, field_name in numeric_columns.items():
                value = _to_float(item.get(field_name))
                if col_num in (9, 11, 13, 15) and value <= 0:
                    continue
                totals[col_num] += value

        merge_range = f'B{row_start}:B{row_end}'
        try:
            ws.unmerge_cells(merge_range)
        except Exception:
            pass
        ws.merge_cells(merge_range)
        _safe_set_cell(ws, row_start, 2, merged_date)
        _set_merged_top_alignment(ws, row_start, 2)

        for col_num, total in totals.items():
            _safe_set_number(ws, row_start, col_num, total)


def _operation_cost_totals_by_column(expenses, cat_names):
    totals = [0.0] * len(cat_names)
    for expense in expenses:
        nominal_idr = _expense_amount_for_display(expense)
        col_idx = _map_expense_category_index_from_name(
            _expense_column_mapping_name(expense),
            cat_names
        )
        totals[col_idx] += nominal_idr
    return totals


def _sync_formatted_secondary_sheets(wb, payload, year, main_sheet_name):
    expenses = payload.get('operation_cost', {}).get('data', [])
    revenues = payload.get('revenue', {}).get('data', [])
    annual_settings = payload.get('dividend', {}).get('settings', {}) or {}

    revenue_total = sum(
        _idr_from_currency(
            row.get('amount_received'),
            row.get('currency'),
            row.get('currency_exchange'),
        )
        for row in revenues
    )
    pph23_total = sum(_to_float(row.get('pph_23')) for row in revenues)
    # Fetch root categories dynamically from DB
    root_cats = Category.query.filter_by(parent_id=None).order_by(Category.id).all()
    cat_names = [c.name for c in root_cats]
    cost_totals = _operation_cost_totals_by_column(expenses, cat_names)
    total_cost = sum(cost_totals)
    profit_before_tax = revenue_total - total_cost
    tax_corporate = max(0.0, profit_before_tax * 0.11) if profit_before_tax > 0 else 0.0
    after_tax = _to_float(payload.get('dividend', {}).get('profit_after_tax'))
    if after_tax == 0 and profit_before_tax > 0:
        after_tax = profit_before_tax - max(0.0, tax_corporate - pph23_total)

    opening_cash_balance = _to_float(annual_settings.get('opening_cash_balance'))
    accounts_receivable = _to_float(annual_settings.get('accounts_receivable'))
    prepaid_tax_pph23 = _to_float(annual_settings.get('prepaid_tax_pph23'))
    prepaid_expenses = _to_float(annual_settings.get('prepaid_expenses'))
    other_receivables = _to_float(annual_settings.get('other_receivables'))
    office_inventory = _to_float(annual_settings.get('office_inventory'))
    other_assets = _to_float(annual_settings.get('other_assets'))
    accounts_payable = _to_float(annual_settings.get('accounts_payable'))
    salary_payable = _to_float(annual_settings.get('salary_payable'))
    shareholder_payable = _to_float(annual_settings.get('shareholder_payable'))
    accrued_expenses = _to_float(annual_settings.get('accrued_expenses'))
    share_capital = _to_float(annual_settings.get('share_capital'))
    retained_earnings_balance = _to_float(annual_settings.get('retained_earnings_balance'))

    main_ref = _sheet_ref(main_sheet_name)

    if main_sheet_name in wb.sheetnames:
        ws_main = wb[main_sheet_name]
        ws_main['F22'] = revenue_total
        ws_main['N22'] = pph23_total
        for idx, value in enumerate(cost_totals, start=9):
            ws_main.cell(row=750, column=idx, value=value)

    lr_name = f'Laba rugi -{year}'
    if lr_name in wb.sheetnames:
        ws_lr = wb[lr_name]
        ws_lr['A3'] = None  # Clean up mistake
        ws_lr['F3'] = None  # Clean up mistake
        ws_lr['B4'] = f'LABA RUGI | TAHUN {year}'
        ws_lr['G4'] = f'NERACA | TAHUN YANG BERAKHIR, 31 DESEMBER {year}'
        # bersihkan nilai template dummy spesifik di neraca
        if ws_lr['J10'].value in (161401093, '=161401093', 161401093.0):
            ws_lr['J10'] = 0

        ws_lr['E9'] = f'=SUM({main_ref}!F8:F20)'
        ws_lr['E10'] = f'=SUM({main_ref}!F21)'
        ws_lr['E12'] = '=SUM(E9:E11)'
        ws_lr['E15'] = f'={main_ref}!I750'
        ws_lr['E16'] = f'={main_ref}!J750'
        ws_lr['E17'] = f'={main_ref}!K750'
        ws_lr['E18'] = f'={main_ref}!L750'
        ws_lr['E21'] = '=SUM(E15:E20)'
        ws_lr['E23'] = f'={main_ref}!Q750'
        ws_lr['E27'] = '=SUM(E22:E26)'
        ws_lr['E30'] = f'={main_ref}!M750'
        ws_lr['E31'] = f'={main_ref}!N750'
        ws_lr['E32'] = f'={main_ref}!O750'
        ws_lr['E33'] = f'={main_ref}!P750'
        ws_lr['E35'] = '=SUM(E30:E34)'
        ws_lr['E37'] = '=E35+E21+E27'
        ws_lr['E40'] = 0
        ws_lr['E42'] = '=E12-E37'
        ws_lr['E44'] = 0
        ws_lr['E46'] = '=E42-E44'

        # input dan formula neraca
        ws_lr['J10'] = opening_cash_balance
        ws_lr['J11'] = "=E46-'Business Summary'!E13"
        ws_lr['J12'] = accounts_receivable
        ws_lr['J13'] = prepaid_tax_pph23
        ws_lr['J14'] = prepaid_expenses
        ws_lr['J15'] = other_receivables
        ws_lr['J16'] = '=SUM(J10:J15)'
        ws_lr['J20'] = office_inventory
        ws_lr['J22'] = '=J20'
        ws_lr['J25'] = other_assets
        ws_lr['J26'] = '=SUM(J25:J25)'
        ws_lr['J28'] = '=J26+J22+J16'
        ws_lr['J33'] = accounts_payable
        ws_lr['J34'] = salary_payable
        ws_lr['J35'] = shareholder_payable
        ws_lr['J36'] = accrued_expenses
        ws_lr['J38'] = '=SUM(J33:J36)'
        ws_lr['J41'] = share_capital
        ws_lr['J42'] = retained_earnings_balance
        ws_lr['J43'] = '=J28-J38-J41-J42'
        ws_lr['J44'] = '=SUM(J41:J43)'
        ws_lr['J46'] = '=J44+J38'

        # DEMONSTRASI KEAMANAN KOLOM: Menulis ke Kolom K (Kolom ke-11)
        # Sesuai saran, kolom K ke kanan adalah "Kolom Aman"
        ws_lr['K4'] = "CATATAN KEAMANAN"
        ws_lr['K4'].font = Font(bold=True)
        ws_lr['K5'] = "Kolom ini aman dari overwrite sistem."
        ws_lr['K6'] = "Diverifikasi pada: " + datetime.now().strftime('%Y-%m-%d %H:%M')

    if 'Business Summary' in wb.sheetnames:
        ws_bs = wb['Business Summary']
        ws_bs['A4'] = None  # Clean up mistake
        ws_bs['B4'] = f'BUSINESS SUMMARY | TAHUN {year}'
        ws_bs['E7'] = f'={main_ref}!F22'
        ws_bs['E8'] = f'=E7-{main_ref}!N22'
        ws_bs['E9'] = f'=SUM({main_ref}!I750:Q750)'
        ws_bs['E10'] = '=E7-E9'
        ws_bs['E11'] = '=E10*22%*50%'
        ws_bs['E12'] = f'={main_ref}!N22'
        ws_bs['E13'] = '=E11-E12'
        ws_bs['E14'] = '=E10-E13'
        dividends = payload.get('dividend', {}).get('data', [])
        profit_retained = _to_float(payload.get('dividend', {}).get('profit_retained'))
        ws_bs['E15'] = '=E14-E16'
        ws_bs['E16'] = profit_retained

        # buat ulang baris penerima dari data app. jumlah yang dibagikan
        # didapat dari profit after tax - profit ditahan, lalu dibagi rata.
        for row in range(19, 80):
            for col in ('A', 'B', 'C', 'D', 'E', 'F', 'G'):
                try:
                    ws_bs[f'{col}{row}'] = None
                except Exception:
                    pass
        for idx, item in enumerate(dividends, 1):
            row = 18 + idx
            ws_bs[f'A{row}'] = idx  # Nomor urut
            ws_bs[f'B{row}'] = item.get('name', '')  # Nama lengkap penerima
            ws_bs[f'D{row}'] = 'Rp'
            ws_bs[f'E{row}'] = f'=IF(B{row}="","",$E$15/COUNTA($B$19:$B$79))'
            ws_bs[f'G{row}'] = 'Pajak 10%'  # Keterangan pajak

def _clone_sheet_from_template(src_ws, target_wb, new_name):
    if new_name in target_wb.sheetnames: del target_wb[new_name]
    dst_ws = target_wb.create_sheet(new_name)
    dst_ws.sheet_format = copy(src_ws.sheet_format); dst_ws.sheet_properties = copy(src_ws.sheet_properties)
    dst_ws.page_margins = copy(src_ws.page_margins); dst_ws.page_setup = copy(src_ws.page_setup)
    dst_ws.print_options = copy(src_ws.print_options); dst_ws.freeze_panes = src_ws.freeze_panes
    dst_ws.auto_filter = copy(src_ws.auto_filter)
    for col_letter, col_dim in src_ws.column_dimensions.items():
        dst = dst_ws.column_dimensions[col_letter]; dst.width = col_dim.width; dst.hidden = col_dim.hidden
        dst.outlineLevel = col_dim.outlineLevel; dst.bestFit = col_dim.bestFit
    for row_idx, row_dim in src_ws.row_dimensions.items():
        dst = dst_ws.row_dimensions[row_idx]; dst.height = row_dim.height; dst.hidden = row_dim.hidden; dst.outlineLevel = row_dim.outlineLevel
    for row in src_ws.iter_rows(min_row=1, max_row=src_ws.max_row, min_col=1, max_col=src_ws.max_column):
        for cell in row:
            dst = dst_ws.cell(row=cell.row, column=cell.column, value=cell.value)
            if cell.has_style:
                dst.font = copy(cell.font); dst.fill = copy(cell.fill); dst.border = copy(cell.border)
                dst.alignment = copy(cell.alignment); dst.number_format = copy(cell.number_format); dst.protection = copy(cell.protection)
    for merged in src_ws.merged_cells.ranges: dst_ws.merge_cells(str(merged))
    return dst_ws


def _ensure_formatted_secondary_sheets(wb, year, template_dir):
    target_lr = f'Laba rugi -{year}'; target_bs = 'Business Summary'

    # Hapus semua sheet Laba rugi yang lama (dari template)
    sheets_to_remove = [name for name in wb.sheetnames if name.startswith('Laba rugi -') and name != target_lr]
    for sheet_name in sheets_to_remove:
        if sheet_name in wb.sheetnames:
            del wb[sheet_name]

    if target_lr in wb.sheetnames and target_bs in wb.sheetnames: return True

    donor_candidates = [
        os.path.abspath(os.path.join(template_dir, '20250427_EWI Financial-Repport_2024_Submitted_Rev1.xlsx')),
        os.path.abspath(os.path.join(template_dir, 'Revenue-Cost_2024_cleaned.xlsx')),
    ]
    donor_path = next((p for p in donor_candidates if os.path.exists(p)), None)
    if not donor_path: return False

    donor_wb = load_workbook(donor_path, keep_links=False)

    # Cari sheet Laba rugi (bisa Laba rugi -2024 atau nama lain)
    donor_lr_name = next((name for name in donor_wb.sheetnames if name.startswith('Laba rugi')), None)
    donor_lr = donor_wb[donor_lr_name] if donor_lr_name else None

    # Cari sheet Business Summary
    donor_bs_name = next((name for name in donor_wb.sheetnames if name == 'Business Summary'), None)
    donor_bs = donor_wb[donor_bs_name] if donor_bs_name else None

    if donor_lr is None or donor_bs is None: return False

    _clone_sheet_from_template(donor_lr, wb, target_lr)
    _clone_sheet_from_template(donor_bs, wb, target_bs)
    return True


@reports_bp.route('/annual', methods=['GET'])
@jwt_required()
def get_annual_report():
    user = User.query.get(int(get_jwt_identity()))
    year = request.args.get('year', _default_report_year(), type=int)
    payload = _build_annual_payload_from_db(year)
    payload['cache_source'] = 'refresh'
    saved_payload = _save_annual_payload_cache(year, payload)
    _save_annual_pdf_cache(year, _build_annual_pdf_bytes(saved_payload))
    return jsonify(saved_payload), 200


@reports_bp.route('/annual/pdf', methods=['GET'])
@jwt_required()
def get_annual_report_pdf():
    user = User.query.get(int(get_jwt_identity()))
    year = request.args.get('year', _default_report_year(), type=int)
    filename = f"Laporan_Tahunan_{year}.pdf"
    payload = _save_annual_payload_cache(year, _build_annual_payload_from_db(year))
    pdf_path = _save_annual_pdf_cache(year, _build_annual_pdf_bytes(payload))
    return send_file(pdf_path, as_attachment=True, download_name=filename, mimetype='application/pdf')


@reports_bp.route('/annual/excel', methods=['GET'])
@jwt_required()
def get_annual_report_excel():
    user = User.query.get(int(get_jwt_identity()))
    year = request.args.get('year', _default_report_year(), type=int)

    print(f'[ANNUAL_EXCEL] Starting export for year={year}')

    payload = _save_annual_payload_cache(year, _build_annual_payload_from_db(year))
    revenues = payload.get('revenue', {}).get('data', [])
    taxes = payload.get('tax', {}).get('data', [])
    expenses = payload.get('operation_cost', {}).get('data', [])

    print(f'[ANNUAL_EXCEL] Data loaded: {len(revenues)} revenues, {len(taxes)} taxes, {len(expenses)} expenses')

    revenue_combine_groups = _manual_combine_groups_by_table('revenues', year)
    tax_combine_groups = _manual_combine_groups_by_table('taxes', year)
    imported_source_name = None
    try:
        imported_source_name = db.session.execute(sql_text(
            """SELECT source_excel FROM report_entry_tags
               WHERE report_year = :year AND source_excel IS NOT NULL AND TRIM(source_excel) <> ''
               ORDER BY imported_at DESC, id DESC LIMIT 1"""),
            {'year': int(year)}).scalar()
    except Exception:
        imported_source_name = None
    template_dir = os.path.abspath(os.path.join(current_app.root_path, '..', 'excel'))
    template_candidates = []
    if imported_source_name:
        template_candidates.extend([
            os.path.abspath(os.path.join(template_dir, imported_source_name)),
            os.path.abspath(os.path.join(current_app.root_path, '..', 'data', imported_source_name)),
        ])
    template_candidates.extend([
        os.path.abspath(os.path.join(template_dir, 'Revenue-Cost_2024_cleaned_asli_cleaned.xlsx')),
        os.path.abspath(os.path.join(template_dir, 'Revenue-Cost_2024_cleaned.xlsx')),
    ])
    template_path = next((p for p in template_candidates if os.path.exists(p)), template_candidates[0])

    print(f'[ANNUAL_EXCEL] Template path: {template_path}')

    if not os.path.exists(template_path):
        print(f'[ANNUAL_EXCEL] ERROR: Template not found: {template_path}')
        return jsonify({'error': f'Template tidak ditemukan: {template_path}'}), 404
    wb = load_workbook(template_path, keep_links=False)
    _normalize_external_formula_refs(wb)

    print(f'[ANNUAL_EXCEL] Template loaded, processing sheets...')

    # Hapus semua sheet Laba rugi yang lama dari template (akan dibuat ulang dengan tahun yang benar)
    sheets_to_remove = [name for name in wb.sheetnames if name.startswith('Laba rugi -')]
    for sheet_name in sheets_to_remove:
        del wb[sheet_name]

    # Cari sheet Revenue-Cost (bisa Revenue-Cost_2024 atau nama lain)
    revenue_cost_sheet_name = next((name for name in wb.sheetnames if name.startswith('Revenue-Cost')), None)
    if revenue_cost_sheet_name:
        ws = wb[revenue_cost_sheet_name]
        # Rename sheet dengan tahun yang benar
        ws.title = f'Revenue-Cost_{year}'
    else:
        ws = wb.active
        ws.title = f'Revenue-Cost_{year}'

    # Update header document dengan tahun yang benar
    _safe_set_cell(ws, 2, 4, f'REVENUE vs OPERATION COST Tahun {year}')
    _safe_set_cell(ws, 3, 4, f'Januari - Desember {year}')

    visible_tax_rows = max(1, min(len(taxes), 10))
    tax_last_visible = 26 + visible_tax_rows
    _set_rows_hidden(ws, 27, 36, False)
    if tax_last_visible < 36: _set_rows_hidden(ws, tax_last_visible + 1, 36, True)
    _apply_manual_tax_combine_groups(
        ws,
        taxes[:visible_tax_rows],
        tax_combine_groups,
        start_row=27,
    )
    if not taxes:
        _safe_set_cell(ws, 27, 3, 1); _safe_set_cell(ws, 27, 4, 'Belum ada data pajak'); _safe_set_cell(ws, 27, 7, 'IDR'); _safe_set_cell(ws, 27, 8, 1)
    sum_tax1 = sum(_to_float(t.get('ppn')) for t in taxes[:10])
    sum_tax2 = sum(_to_float(t.get('pph_21')) for t in taxes[:10])
    sum_tax3 = sum(_to_float(t.get('pph_23')) for t in taxes[:10])
    sum_tax4 = sum(_to_float(t.get('pph_26')) for t in taxes[:10])

    _safe_set_cell(ws, 37, 2, 'PENERIMAAN NEGARA (TAX) (IDR)')
    _safe_set_cell(ws, 37, 9, 'PPN'); _safe_set_cell(ws, 37, 10, sum_tax1)
    _safe_set_cell(ws, 37, 11, 'PPh'); _safe_set_cell(ws, 37, 12, sum_tax2)
    _safe_set_cell(ws, 37, 13, 'PPh'); _safe_set_cell(ws, 37, 14, sum_tax3)
    _safe_set_cell(ws, 37, 15, 'PPh'); _safe_set_cell(ws, 37, 16, sum_tax4)
    _safe_set_cell(ws, 37, 17, '-')
    # Fetch root categories dynamically from DB - ORDER BY sort_order (from Kategori Tabular)
    root_cats = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
    cat_columns = [c.name for c in root_cats]
    cat_names = cat_columns # for mapping
    _write_dynamic_category_headers(ws, root_cats)

    # Table 3: PENGELUARAN & OPERATION COST (summary)
    base_summary_start = 41
    base_summary_end = 96
    summary_data_rows = []
    for r in range(base_summary_start, base_summary_end + 1):
        seq_val = ws.cell(row=r, column=3).value
        seq_num = None
        if isinstance(seq_val, (int, float)):
            seq_num = int(seq_val)
        else:
            seq_text = _safe_text(seq_val).strip()
            if seq_text.isdigit():
                seq_num = int(seq_text)
        if seq_num is not None:
            summary_data_rows.append(r)

    summary_items = [
        e for e in expenses
        if not _is_batch_settlement(e.get('settlement_type'), e.get('settlement_title'))
    ]
    summary_items = sorted(
        summary_items,
        key=lambda e: (
            _extract_imported_row(e.get('notes')) is None,
            _extract_imported_row(e.get('notes')) or 10**9,
            int(e.get('id') or 0),
        ),
    )

    summary_groups = OrderedDict()
    for expense in summary_items:
        group_label = _expense_subcategory_label(expense) or '-'
        summary_groups.setdefault(group_label, []).append(expense)

    ordered_summary_groups = OrderedDict(
        sorted(summary_groups.items(), key=lambda item: item[0].lower())
    )

    required_rows = len(summary_items) + len(ordered_summary_groups)
    available_rows = base_summary_end - base_summary_start + 1
    extra_rows_needed = max(0, required_rows - available_rows)
    first_expense_header_row = _get_expense_blocks(ws)[0][1] if _get_expense_blocks(ws) else (base_summary_end + 1)
    if extra_rows_needed > 0:
        ws.insert_rows(first_expense_header_row, extra_rows_needed)
        for offset in range(extra_rows_needed):
            _clone_row_format(ws, summary_data_rows[-1], first_expense_header_row + offset)

    summary_end_row = base_summary_end + extra_rows_needed
    all_summary_rows = list(range(base_summary_start, summary_end_row + 1))
    for r in all_summary_rows:
        _clear_range(ws, r, r, 2, 17)
        _set_rows_hidden(ws, r, r, False)

    row_cursor = base_summary_start
    seq_counter = 1
    white_fill = PatternFill(fill_type='solid', fgColor='FFFFFF')
    for group_label, group_items in ordered_summary_groups.items():
        for col in range(2, 18):
            cell = ws.cell(row=row_cursor, column=col)
            if isinstance(cell, MergedCell):
                continue
            cell.fill = copy(white_fill)
        _safe_set_cell(ws, row_cursor, 4, group_label)
        ws.cell(row=row_cursor, column=4).font = Font(bold=True)
        row_cursor += 1

        for expense in group_items:
            for col in range(2, 18):
                cell = ws.cell(row=row_cursor, column=col)
                if isinstance(cell, MergedCell):
                    continue
                cell.fill = copy(white_fill)
            clean_desc = re.sub(r'^\[.*?\]\s*', '', (expense.get('description') or '').strip()).strip()
            _safe_set_cell(ws, row_cursor, 2, _parse_iso_date(expense.get('date')))
            _safe_set_cell(ws, row_cursor, 3, seq_counter)
            _safe_set_cell(ws, row_cursor, 4, clean_desc or '-')
            _safe_set_cell(ws, row_cursor, 5, expense.get('source') or '-')
            _safe_set_number(ws, row_cursor, 6, _expense_amount_for_display(expense))
            _safe_set_cell(ws, row_cursor, 7, expense.get('currency') or 'IDR')
            _safe_set_number(
                ws,
                row_cursor,
                8,
                _to_float(expense.get('currency_exchange'), default=1) or 1,
                number_format='0.########',
            )
            root_name = _expense_column_mapping_name(expense)
            fallback_col = 9 + _map_expense_category_index_from_name(
                root_name,
                cat_names
            )
            nominal_idr = _expense_amount_for_display(expense)
            _safe_set_number(ws, row_cursor, fallback_col, nominal_idr)
            row_cursor += 1
            seq_counter += 1

    if not summary_items:
        _safe_set_cell(ws, base_summary_start, 3, 1)
        _safe_set_cell(ws, base_summary_start, 4, '-')
        _safe_set_cell(ws, base_summary_start, 5, '-')
        _safe_set_cell(ws, base_summary_start, 7, 'IDR')
        _safe_set_cell(ws, base_summary_start, 8, 1)
        row_cursor = base_summary_start + 1

    if row_cursor <= summary_end_row:
        _set_rows_hidden(ws, row_cursor, summary_end_row, True)

    actual_first_expense_header_row = first_expense_header_row + extra_rows_needed
    operation_title_row = actual_first_expense_header_row - 1
    for col in range(2, 18):
        cell = ws.cell(row=operation_title_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        if col != 4:
            cell.value = None
    _safe_set_cell(
        ws,
        operation_title_row,
        4,
        'OPERATION COST AND OFFICE - Expenses Report',
    )
    ws.cell(row=operation_title_row, column=4).font = Font(bold=True)
    # Expense detail blocks
    all_categories = Category.query.all()
    category_by_id_map = {c.id: c for c in all_categories}
    all_groups = _group_annual_expenses(expenses, year)
    groups = [g for g in all_groups if g and _is_batch_settlement(g[0].get('settlement_type'), g[0].get('settlement_title'))]
    group_by_header_row = {}; groups_without_header = []
    for group in groups:
        first = group[0] if group else {}
        header_row = _extract_imported_sheet_row(first.get('settlement_description'))
        if header_row is None:
            groups_without_header.append(group)
            continue
        if extra_rows_needed > 0 and header_row >= first_expense_header_row:
            header_row += extra_rows_needed
        group_by_header_row[header_row] = group
    fallback_group_idx = 0
    expense_blocks = _get_expense_blocks(ws)
    for _, header_row, start_row, end_row in expense_blocks:
        block_items = group_by_header_row.get(header_row)
        if block_items is None:
            if fallback_group_idx < len(groups_without_header): block_items = groups_without_header[fallback_group_idx]; fallback_group_idx += 1
            else: block_items = []
        detail_data_rows = [r for r in range(start_row, end_row + 1) if _is_template_detail_data_row(ws, r)]
        subcategory_rows = [r for r in range(start_row, end_row + 1) if (not _is_template_detail_data_row(ws, r)) and _safe_text(ws.cell(row=r, column=4).value).strip()]
        template_seq_block = {r: ws.cell(row=r, column=3).value for r in detail_data_rows}
        if not block_items:
            _safe_set_cell(ws, header_row, 4, None); _set_rows_hidden(ws, header_row, end_row, True); continue
        _set_rows_hidden(ws, header_row, end_row, False)
        settlement_name = _clean_settlement_title(block_items[0].get('settlement_title') or 'Tanpa Settlement')
        _safe_set_cell(ws, header_row, 4, settlement_name)
        ws.cell(row=header_row, column=2).font = Font(bold=True); ws.cell(row=header_row, column=4).font = Font(bold=True)
        _render_batch_expense_block(
            ws,
            start_row,
            end_row,
            block_items,
            cat_names,
            category_by_id_map,
        )
        continue

        # Kumpulkan subcategory headers dan ranges-nya
        section_headers_unsorted = []
        section_ranges_unsorted = []
        current_header = None
        current_rows = []
        for r in range(start_row, end_row + 1):
            if r in subcategory_rows:
                if current_header is not None:
                    section_ranges_unsorted.append((current_header, list(current_rows)))
                current_header = r
                current_rows = []
                subtitle = _safe_text(ws.cell(row=r, column=4).value).strip()
                if subtitle:
                    ws.cell(row=r, column=4).font = Font(bold=True)
                    section_headers_unsorted.append((r, subtitle))
            elif r in detail_data_rows and current_header is not None:
                current_rows.append(r)
        if current_header is not None:
            section_ranges_unsorted.append((current_header, list(current_rows)))
        if not detail_data_rows: continue

        # SORT section headers alphabetically (A-Z)
        section_headers_sorted = sorted(section_headers_unsorted, key=lambda item: item[1].lower())

        # Rebuild section_ranges based on sorted headers
        section_ranges_sorted = []
        for header_row_num, subtitle in section_headers_sorted:
            for orig_header, orig_rows in section_ranges_unsorted:
                if orig_header == header_row_num:
                    section_ranges_sorted.append((orig_header, orig_rows))
                    break

        placement_rows2 = {}
        used_rows2 = set()

        # Urutkan item berdasarkan sub-kategori A-Z (sama seperti single)
        # Group items by subcategory first
        items_grouped_by_subcategory = OrderedDict()
        for e in block_items:
            subcategory = (_expense_subcategory_label(e) or '').strip()
            if subcategory:
                items_grouped_by_subcategory.setdefault(subcategory, []).append(e)

        # Sort subcategories alphabetically (A-Z)
        sorted_subcategories = sorted(items_grouped_by_subcategory.keys(), key=lambda x: x.lower())

        ordered_items = sorted(
            block_items,
            key=lambda e: (
                (_expense_subcategory_label(e) or '').lower(),
                _extract_imported_row(e.get('notes')) is None,
                _extract_imported_row(e.get('notes')) or 10**9,
                int(e.get('id') or 0),
            ),
        )

        header_lookup = OrderedDict()
        for row_num, subtitle in section_headers_sorted:
            key = _safe_text(subtitle).strip().lower()
            header_lookup.setdefault(key, []).append(row_num)

        section_rows_lookup = {
            header_row_num: rows
            for header_row_num, rows in section_ranges_sorted
        }

        items_by_subcategory = OrderedDict()
        uncategorized_items = []
        for e in ordered_items:
            subcategory = (_expense_subcategory_label(e) or '').strip()
            key = subcategory.lower()
            if key and key in header_lookup:
                items_by_subcategory.setdefault(key, []).append(e)
            else:
                uncategorized_items.append(e)

        hidden_headers = set(subcategory_rows)
        hidden_detail_rows = set(detail_data_rows)

        for sub_key, items in items_by_subcategory.items():
            candidate_headers = header_lookup.get(sub_key, [])
            available_rows = []
            for header_row_num in candidate_headers:
                available_rows.extend(section_rows_lookup.get(header_row_num, []))
            if not available_rows:
                uncategorized_items.extend(items)
                continue

            rows_for_items = available_rows[:len(items)]
            for row_num, e in zip(rows_for_items, items):
                placement_rows2[row_num] = e
                used_rows2.add(row_num)

        remaining_rows = [
            r for r in detail_data_rows
            if r not in used_rows2
        ]
        for row_num, e in zip(remaining_rows, uncategorized_items):
            placement_rows2[row_num] = e
            used_rows2.add(row_num)
            hidden_detail_rows.discard(row_num)

        for header_row_num, rows in section_ranges_sorted:
            if any(r in placement_rows2 for r in rows):
                hidden_headers.discard(header_row_num)
                for r in rows:
                    if r in placement_rows2:
                        hidden_detail_rows.discard(r)

        header_rows_by_title = OrderedDict()
        for row_num, subtitle in section_headers_sorted:
            key = _safe_text(subtitle).strip().lower()
            header_rows_by_title.setdefault(key, []).append(row_num)

        # MOVE header text to sorted positions ← FIX!
        # Get sorted header titles
        sorted_titles = [subtitle for row_num, subtitle in section_headers_sorted]

        # Get header rows in order (from sorted ranges)
        header_rows_in_order = [row_num for row_num, rows in section_ranges_sorted]

        # Clear all original headers
        for orig_row_num, orig_subtitle in section_headers_unsorted:
            ws.cell(row=orig_row_num, column=4).value = None

        # Write sorted headers to header rows
        for idx, header_row in enumerate(header_rows_in_order):
            if idx < len(sorted_titles):
                ws.cell(row=header_row, column=4).value = sorted_titles[idx]
                ws.cell(row=header_row, column=4).font = Font(bold=True)

        for title_key, header_rows in header_rows_by_title.items():
            if not title_key:
                continue
            has_any_items = any(
                any(r in placement_rows2 for r in section_rows_lookup.get(header_row_num, []))
                for header_row_num in header_rows
            )
            if not has_any_items:
                continue

            first_header = min(header_rows)
            hidden_headers.discard(first_header)
            for duplicate_header in header_rows:
                if duplicate_header != first_header:
                    hidden_headers.add(duplicate_header)

        for idx, row_num in enumerate(sorted(placement_rows2.keys()), 1):
            e = placement_rows2[row_num]
            seq_value = template_seq_block.get(row_num)
            seq_num = int(seq_value) if isinstance(seq_value, (int, float)) else idx
            clean_desc = re.sub(r'^\[.*?\]\s*', '', (e.get('description') or '').strip())
            _clear_range(ws, row_num, row_num, 2, 17)
            _safe_set_cell(ws, row_num, 2, _parse_iso_date(e.get('date'))); _safe_set_cell(ws, row_num, 3, seq_num)
            _safe_set_cell(ws, row_num, 4, clean_desc); _safe_set_number(ws, row_num, 6, _expense_amount_for_display(e))
            _safe_set_cell(ws, row_num, 7, e.get('currency') or 'IDR'); _safe_set_number(ws, row_num, 8, _to_float(e.get('currency_exchange'), default=1) or 1, number_format='0.########')
            info = _root_category_info(e.get('category_id'), category_by_id_map)
            root_name = info[0]
            fallback_col = 9 + _map_expense_category_index_from_name(root_name, cat_names)
            nominal_idr = _expense_amount_for_display(e)
            _safe_set_number(ws, row_num, fallback_col, nominal_idr)
        for r in hidden_headers:
            _safe_set_cell(ws, r, 4, None)
            _set_rows_hidden(ws, r, r, True)
        for r in hidden_detail_rows:
            _clear_range(ws, r, r, 2, 17)
            _set_rows_hidden(ws, r, r, True)
    final_main_sheet_name = f'Revenue-Cost_{year}'
    if ws.title != final_main_sheet_name:
        ws.title = final_main_sheet_name

    has_formatted_secondary = _ensure_formatted_secondary_sheets(wb, year, template_dir)
    if not has_formatted_secondary:
        _write_secondary_summary_sheets(wb, payload, year, final_main_sheet_name)
    _sync_formatted_secondary_sheets(wb, payload, year, final_main_sheet_name)
    try:
        wb.calculation.calcMode = 'auto'
        wb.calculation.fullCalcOnLoad = True
        wb.calculation.forceFullCalc = True
    except Exception:
        pass

    print(f'[ANNUAL_EXCEL] Export completed, sending file...')

    buffer = BytesIO(); wb.save(buffer); buffer.seek(0)
    filename = f'Revenue-Cost_{year}.xlsx'
    return send_file(buffer, as_attachment=True, download_name=filename, mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
