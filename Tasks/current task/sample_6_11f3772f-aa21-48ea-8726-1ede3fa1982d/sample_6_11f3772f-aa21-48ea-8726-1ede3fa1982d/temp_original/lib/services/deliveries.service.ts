import { apiClient } from '../api/client'
import { Page, PaginationParams } from '../api/types'
import { Delivery } from '../types/entities/delivery.types'

export const deliveriesService = {
    async getAll(params?: PaginationParams): Promise<Page<Delivery>> {
        const response = await apiClient.get<Page<Delivery>>('/deliveries', { params })
        return response.data
    },
    async delete(id: string, deletedBy: string): Promise<void> {
        await apiClient.delete(`/deliveries/${id}`, { params: { deletedBy } })
    },
}
