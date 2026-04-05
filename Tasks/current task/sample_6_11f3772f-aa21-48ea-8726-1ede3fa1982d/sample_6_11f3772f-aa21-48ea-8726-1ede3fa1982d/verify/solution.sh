#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting solution application..."

# 1. Locate files systematically
log "Searching for target files..."
TYPES_FILE=$(find . -name "delivery.types.ts" | grep "entities" | head -n 1)
TABLE_FILE=$(find . -name "delivery-table.tsx" | grep "deliveries" | head -n 1)
PAGE_FILE=$(find . -name "page.tsx" | grep "deliveries" | grep -v "\[id\]" | head -n 1)
PAGINATION_FILE=$(find . -name "pagination.tsx" | grep "common" | head -n 1)

# 2. Fix Pagination Component Props
# The environment provided a dummy Pagination component that didn't accept props, causing build errors.
if [[ -n "$PAGINATION_FILE" && -f "$PAGINATION_FILE" ]]; then
    log "Updating Pagination component in $PAGINATION_FILE to handle props..."
    cat << 'EOF' > "$PAGINATION_FILE"
'use client'
import React from 'react'

interface PaginationProps {
  currentPage: number
  totalPages: number
  pageSize: number
  totalItems: number
  onPageChange: (page: number) => void
  onPageSizeChange: (size: number) => void
}

export const Pagination = ({ 
  currentPage, 
  totalPages, 
  pageSize, 
  totalItems, 
  onPageChange, 
  onPageSizeChange 
}: PaginationProps) => {
  return (
    <div className="flex items-center justify-between px-2 py-4 border-t">
      <div className="text-sm text-gray-500">
        Showing {totalItems > 0 ? (currentPage - 1) * pageSize + 1 : 0} to {Math.min(currentPage * pageSize, totalItems)} of {totalItems} items
      </div>
      <div className="flex gap-2">
        <button 
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          className="px-3 py-1 border rounded disabled:opacity-50"
        >
          Previous
        </button>
        <button 
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          className="px-3 py-1 border rounded disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  )
}
EOF
fi

# 3. Update Delivery Type Definitions
if [[ -n "$TYPES_FILE" && -f "$TYPES_FILE" ]]; then
    log "Updating types in $TYPES_FILE..."
    cat << 'EOF' > "$TYPES_FILE"
import { OmitAuditFields } from '../common.types'

export enum DeliveryStatus {
  SCHEDULED = 'SCHEDULED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export interface DeliveryAddress {
  addressLine1: string;
  city: string;
  state: string;
  zipCode: string;
}

export interface Delivery {
  id: string;
  deliveredById: string;
  deliveredByName: string;
  addressId: string;
  address: DeliveryAddress;
  deliveryDate: string;
  status?: DeliveryStatus;
  notes?: string | null;
  createdAt?: string;
  updatedAt?: string;
  createdBy?: string;
  updatedBy?: string;
}

export type DeliveryRequestDto = Omit<Delivery, 'id' | 'deliveredByName' | 'address' | 'createdAt' | 'updatedAt' | 'createdBy' | 'updatedBy'>;

export type DeliveryResponseDto = Delivery;

export const deliveryStatusConfig: Record<
  DeliveryStatus,
  { label: string; color: string; variant: 'default' | 'secondary' | 'destructive' | 'outline' }
> = {
  [DeliveryStatus.SCHEDULED]: { label: 'Scheduled', color: 'bg-yellow-500', variant: 'outline' },
  [DeliveryStatus.IN_PROGRESS]: { label: 'In Progress', color: 'bg-blue-500', variant: 'default' },
  [DeliveryStatus.COMPLETED]: { label: 'Completed', color: 'bg-green-500', variant: 'default' },
  [DeliveryStatus.CANCELLED]: { label: 'Cancelled', color: 'bg-red-500', variant: 'destructive' },
}
EOF
fi

# 4. Update DeliveryTable UI component
if [[ -n "$TABLE_FILE" && -f "$TABLE_FILE" ]]; then
    log "Updating UI component in $TABLE_FILE..."
    cat << 'EOF' > "$TABLE_FILE"
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Edit, Trash2, Eye } from 'lucide-react'
import { Delivery } from '@/lib/types/entities/delivery.types'
import { formatDate } from '@/lib/utils/date'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
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
    return <div className="text-center py-12 text-muted-foreground">No deliveries found</div>
  }

  return (
    <>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Delivery ID</TableHead>
              <TableHead>Delivered By Name</TableHead>
              <TableHead>Full Address</TableHead>
              <TableHead>Delivery Date</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {deliveries.map((delivery) => (
              <TableRow key={delivery.id}>
                <TableCell className="font-medium">
                  {delivery.id.substring(0, 8)}
                </TableCell>
                <TableCell>{delivery.deliveredByName}</TableCell>
                <TableCell>
                  {delivery.address ? `${delivery.address.addressLine1}, ${delivery.address.zipCode}` : 'N/A'}
                </TableCell>
                <TableCell className="text-muted-foreground">
                  {formatDate(delivery.deliveryDate, 'MM/dd/yyyy')}
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end gap-2">
                    <Button variant="ghost" size="icon" asChild title="View details">
                      <Link href={ROUTES.deliveries.detail(delivery.id)}><Eye className="h-4 w-4" /></Link>
                    </Button>
                    <Button variant="ghost" size="icon" asChild title="Edit delivery">
                      <Link href={ROUTES.deliveries.detail(delivery.id)}><Edit className="h-4 w-4" /></Link>
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
            ))}
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
EOF
fi

# 5. Build Fix (Force Dynamic)
if [[ -n "$PAGE_FILE" && -f "$PAGE_FILE" ]]; then
    log "Applying dynamic build fix to $PAGE_FILE..."
    if ! grep -q "force-dynamic" "$PAGE_FILE"; then
        sed -i "/'use client'/a export const dynamic = 'force-dynamic';" "$PAGE_FILE"
    fi
fi

log "Running build verification..."
npm run build
log "Solution successfully applied."