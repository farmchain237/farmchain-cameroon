import { Controller, Get, Patch, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PrismaService } from '../common/prisma.module';

@UseGuards(AuthGuard('jwt'))
@Controller('admin')
export class AdminController {
  constructor(private prisma: PrismaService) {}

  @Get('users')
  async users() {
    return this.prisma.user.findMany({
      select: { id: true, fullName: true, phone: true, role: true,
                isVerified: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  @Get('orders')
  async orders() {
    return this.prisma.order.findMany({
      include: { listing: true, buyer: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  @Get('stats')
  async stats() {
    const [totalUsers, activeListings, disputedOrders, revenueData, feesData] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.listing.count({ where: { status: 'ACTIVE' } }),
        this.prisma.order.count({ where: { status: 'DISPUTED' } }),
        this.prisma.order.aggregate({
          _sum: { totalPriceXaf: true },
          where: { status: 'RELEASED' },
        }),
        this.prisma.order.aggregate({
          _sum: { feeXaf: true },
          where: { status: 'RELEASED' },
        }),
      ]);
    return {
      totalUsers,
      activeListings,
      disputes: disputedOrders,
      totalRevenueXaf: revenueData._sum.totalPriceXaf ?? 0,
      totalFeesXaf: feesData._sum.feeXaf ?? 0,
    };
  }

  @Patch('users/:id/suspend')
  async suspendUser(@Param('id') id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { isVerified: false },
    });
  }
}
