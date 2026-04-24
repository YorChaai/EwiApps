"""add date indexes for report queries

Revision ID: c1f7f67b9a12
Revises: 574e15ccd7bd
Create Date: 2026-04-23 10:30:00.000000

"""
from alembic import op


# revision identifiers, used by Alembic.
revision = 'c1f7f67b9a12'
down_revision = '574e15ccd7bd'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('expenses', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_expenses_date'), ['date'], unique=False)

    with op.batch_alter_table('revenues', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_revenues_invoice_date'), ['invoice_date'], unique=False)

    with op.batch_alter_table('taxes', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_taxes_date'), ['date'], unique=False)

    with op.batch_alter_table('dividends', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_dividends_date'), ['date'], unique=False)


def downgrade():
    with op.batch_alter_table('dividends', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_dividends_date'))

    with op.batch_alter_table('taxes', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_taxes_date'))

    with op.batch_alter_table('revenues', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_revenues_invoice_date'))

    with op.batch_alter_table('expenses', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_expenses_date'))
