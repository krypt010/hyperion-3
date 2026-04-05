'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Edit, Trash2, Eye } from 'lucide-react'
import { Delivery, DeliveryStatus, deliveryStatusConfig } from '@/lib/types/entities/delivery.types'
import { formatDate, formatDateTime } from '@/lib/utils/date'
import { Button } from '@/components/ui/button'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { ConfirmDialog } from '@/components/common/confirm-dialog'
import { ROUTES } from '@/lib/constants/routes'

interface DeliveryTableProps {
    deliveries: Delivery[]
    onDelete: (id: string) => void
    isDeleting?: boolean
}

export function DeliveryTable({ deliveries, onDelete, isDeleting }: DeliveryTableProps) {
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    const [selectedDeliveryId, setSelectedDeliveryId] = useState<string | null>(null)

    const handleDeleteClick = (deliveryId: string) => {
        setSelectedDeliveryId(deliveryId)
        setDeleteDialogOpen(true)
    }

    const handleConfirmDelete = () => {
        if (selectedDeliveryId) {
            onDelete(selectedDeliveryId)
            setDeleteDialogOpen(false)
            setSelectedDeliveryId(null)
        }
    }

    if (deliveries.length === 0) {
        return (
            <div className="text-center py-12 text-muted-foreground">
                No deliveries found
            </div>
        )
    }

    return (
        <>
            <div className="rounded-md border">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Delivery ID</TableHead>
                            <TableHead>Delivered By</TableHead>
                            <TableHead>Address</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead>Delivery Date</TableHead>
                            <TableHead>Created</TableHead>
                            <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {deliveries.map((delivery) => {
                            const statusConfig = delivery.status
                                ? deliveryStatusConfig[delivery.status as DeliveryStatus]
                                : deliveryStatusConfig[DeliveryStatus.SCHEDULED]
                            return (
                                <TableRow key={delivery.id}>
                                    <TableCell className="font-medium">
                                        Delivery ID: {delivery.id.substring(0, 8)}...
                                    </TableCell>
                                    <TableCell>
                                        Delivered By: {delivery.deliveredById.substring(0, 8)}...
                                    </TableCell>
                                    <TableCell>
                                        Address ID: {delivery.addressId.substring(0, 8)}...
                                    </TableCell>
                                    <TableCell>
                                        {delivery.status ? (
                                            <Badge
                                                variant={statusConfig.variant}
                                                className={statusConfig.color}
                                            >
                                                {statusConfig.label}
                                            </Badge>
                                        ) : (
                                            <Badge variant="outline">N/A</Badge>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-muted-foreground">
                                        {formatDateTime(delivery.deliveryDate)}
                                    </TableCell>
                                    <TableCell className="text-muted-foreground">
                                        {delivery.createdAt ? formatDate(delivery.createdAt) : 'N/A'}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex justify-end gap-2">
                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                asChild
                                                title="View details"
                                            >
                                                <Link href={ROUTES.deliveries.detail(delivery.id)}>
                                                    <Eye className="h-4 w-4" />
                                                </Link>
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                asChild
                                                title="Edit delivery"
                                            >
                                                <Link href={ROUTES.deliveries.detail(delivery.id)}>
                                                    <Edit className="h-4 w-4" />
                                                </Link>
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                onClick={() => handleDeleteClick(delivery.id)}
                                                disabled={isDeleting}
                                                title="Delete delivery"
                                            >
                                                <Trash2 className="h-4 w-4 text-destructive" />
                                            </Button>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            )
                        })}
                    </TableBody>
                </Table>
            </div>
            <ConfirmDialog
                open={deleteDialogOpen}
                onOpenChange={setDeleteDialogOpen}
                onConfirm={handleConfirmDelete}
                title="Delete Delivery"
                description="Are you sure you want to delete this delivery?"
                confirmText="Delete"
                variant="destructive"
            />
        </>
    )
}
