import { OmitAuditFields } from '../common.types'

export enum DeliveryStatus {
    SCHEDULED = 'SCHEDULED',
    IN_PROGRESS = 'IN_PROGRESS',
    COMPLETED = 'COMPLETED',
    CANCELLED = 'CANCELLED',
}

export interface Delivery {
    id: string
    deliveredById: string
    addressId: string
    deliveryDate: string
    status?: DeliveryStatus
    notes?: string | null
    createdAt?: string
    updatedAt?: string
    createdBy?: string
    updatedBy?: string
}

export type DeliveryRequestDto = OmitAuditFields<Delivery>
export type DeliveryResponseDto = Delivery

export const deliveryStatusConfig: Record<
    DeliveryStatus,
    { label: string; color: string; variant: 'default' | 'secondary' | 'destructive' | 'outline' }
> = {
    [DeliveryStatus.SCHEDULED]: { label: 'Scheduled', color: 'bg-yellow-500', variant: 'outline' },
    [DeliveryStatus.IN_PROGRESS]: { label: 'In Progress', color: 'bg-blue-500', variant: 'default' },
    [DeliveryStatus.COMPLETED]: { label: 'Completed', color: 'bg-green-500', variant: 'default' },
    [DeliveryStatus.CANCELLED]: { label: 'Cancelled', color: 'bg-red-500', variant: 'destructive' },
}
