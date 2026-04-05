'use client'

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
