"""Add DeadlineSetting model for notification deadline management

Revision ID: deadline_settings_001
Revises: 
Create Date: 2024-04-27 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'deadline_settings_001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create deadline_settings table
    op.create_table(
        'deadline_settings',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('rule_key', sa.String(length=50), nullable=False),
        sa.Column('days', postgresql.JSON(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('rule_key')
    )


def downgrade():
    op.drop_table('deadline_settings')
