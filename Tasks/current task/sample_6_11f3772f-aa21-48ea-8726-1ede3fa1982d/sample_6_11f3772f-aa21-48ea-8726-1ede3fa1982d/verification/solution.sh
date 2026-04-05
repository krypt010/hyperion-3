#!/bin/bash

# Update lib/types/entities/delivery.types.ts
cat << 'EOF' > env/lib/types/entities/delivery.types.ts
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
  deliveredByName: string
  addressId: string
  address: {
    addressLine1: string
    city: string
    state: string
    zipCode: string
  }
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
EOF

# Update components/deliveries/delivery-table.tsx
cat << 'EOF' > env/components/deliveries/delivery-table.tsx
'use client'

import { Delivery } from '@/lib/types/entities/delivery.types'
import { formatDate } from '@/lib/utils/date'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

interface DeliveryTableProps {
  deliveries: Delivery[]
  onDelete: (id: string) => void
  isDeleting?: boolean
}

export function DeliveryTable({ deliveries }: DeliveryTableProps) {
  if (deliveries.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        No deliveries found
      </div>
    )
  }

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Delivery ID</TableHead>
            <TableHead>Delivered By Name</TableHead>
            <TableHead>Delivery Date</TableHead>
            <TableHead>Full Address</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {deliveries.map((delivery) => {
            return (
              <TableRow key={delivery.id}>
                <TableCell className="font-medium">
                  {delivery.id.substring(0, 8)}
                </TableCell>
                <TableCell>
                  {delivery.deliveredByName}
                </TableCell>
                <TableCell>
                  {formatDate(delivery.deliveryDate, 'MM/dd/yyyy')}
                </TableCell>
                <TableCell>
                  {`${delivery.address.addressLine1}, ${delivery.address.zipCode}`}
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    </div>
  )
}
EOF

# Update app/(app)/deliveries/page.tsx
cat << 'EOF' > env/app/\(app\)/deliveries/page.tsx
'use client'

export const dynamic = 'force-dynamic'

import { useState } from 'react'
import Link from 'next/link'
import { Plus } from 'lucide-react'
import { DeliveryTable } from '@/components/deliveries/delivery-table'
import { Button } from '@/components/ui/button'
import { LoadingPage } from '@/components/common/loading-spinner'
import { ErrorMessage } from '@/components/common/error-message'
import { Pagination } from '@/components/common/pagination'
import { useDeliveries, useDeleteDelivery } from '@/lib/hooks/queries/use-deliveries'
import { ROUTES } from '@/lib/constants/routes'

export default function DeliveriesPage() {
  const [page, setPage] = useState(0)
  const [pageSize, setPageSize] = useState(20)

  const { data, isLoading, error, refetch } = useDeliveries({ page, size: pageSize })
  const deleteDelivery = useDeleteDelivery()

  const handleDelete = (id: string) => {
    deleteDelivery.mutate({ id, deletedBy: '00000000-0000-0000-0000-000000000000' })
  }

  const handlePageChange = (newPage: number) => {
    setPage(newPage - 1)
  }

  const handlePageSizeChange = (newSize: number) => {
    setPageSize(newSize)
    setPage(0)
  }

  if (isLoading) return <LoadingPage />

  if (error) {
    return (
      <ErrorMessage
        message="Failed to load deliveries. Please try again."
        retry={() => refetch()}
      />
    )
  }

  const deliveries = data?.content ?? []
  const totalPages = data?.totalPages ?? 0
  const totalElements = data?.totalElements ?? 0

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground">Manage gas bottle deliveries and schedules</p>
        <Button asChild>
          <Link href={ROUTES.deliveries.new}>
            <Plus className="h-4 w-4 mr-2" />
            Schedule Delivery
          </Link>
        </Button>
      </div>
      <DeliveryTable
        deliveries={deliveries}
        onDelete={handleDelete}
        isDeleting={deleteDelivery.isPending}
      />
      {totalPages > 0 && (
        <Pagination
          currentPage={page + 1}
          totalPages={totalPages}
          pageSize={pageSize}
          totalItems={totalElements}
          onPageChange={handlePageChange}
          onPageSizeChange={handlePageSizeChange}
        />
      )}
    </div>
  )
}
EOF

# Update lib/services/deliveries.service.ts to provide mock data for the new structure
cat << 'EOF' > env/lib/services/deliveries.service.ts
import { Page, PaginationParams } from '../api/types'
import { Delivery, DeliveryStatus } from '../types/entities/delivery.types'

export const deliveriesService = {
  async getAll(params?: PaginationParams): Promise<Page<Delivery>> {
    // Return mock data that matches the new backend structure
    return {
      content: [
        {
          id: 'del-12345678-90ab-cdef',
          deliveredById: 'user-1',
          deliveredByName: 'John Doe',
          addressId: 'addr-1',
          address: {
            addressLine1: '123 Main St',
            city: 'New York',
            state: 'NY',
            zipCode: '10001'
          },
          deliveryDate: '2024-03-24T10:00:00Z',
          status: DeliveryStatus.COMPLETED
        },
        {
          id: 'del-87654321-fedc-ba09',
          deliveredById: 'user-2',
          deliveredByName: 'Jane Smith',
          addressId: 'addr-2',
          address: {
            addressLine1: '456 Elm St',
            city: 'Los Angeles',
            state: 'CA',
            zipCode: '90001'
          },
          deliveryDate: '2024-03-25T14:30:00Z',
          status: DeliveryStatus.SCHEDULED
        }
      ],
      totalPages: 1,
      totalElements: 2,
      size: 20,
      number: 0
    }
  },
  async delete(id: string, deletedBy: string): Promise<void> {
    console.log(`Deleting delivery ${id} by ${deletedBy}`);
  },
}
EOF
