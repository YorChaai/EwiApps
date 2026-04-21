class Status:
    # General Statuses
    DRAFT = 'draft'
    PENDING = 'pending'
    SUBMITTED = 'submitted'
    APPROVED = 'approved'
    REJECTED = 'rejected'

    # Advance Specific
    REVISION_DRAFT = 'revision_draft'
    REVISION_SUBMITTED = 'revision_submitted'
    REVISION_REJECTED = 'revision_rejected'
    IN_SETTLEMENT = 'in_settlement'

    # Legacy
    COMPLETED = 'completed'

class RevenueType:
    DIRECT = 'pendapatan_langsung'
    OTHER = 'pendapatan_lain_lain'

class UserRole:
    MANAGER = 'manager'
    STAFF = 'staff'
    MITRA_EKS = 'mitra_eks'
