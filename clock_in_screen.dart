import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../common/prisma.module';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(private prisma: PrismaService) {}

  // Cron runs in server TZ; set TZ=Africa/Douala in the process env (see .env.example)
  // so '59 23 * * *' lines up with local midnight-eve as required.
  @Cron('59 23 * * *', { timeZone: 'Africa/Douala' })
  async generateDailyReports() {
    this.logger.log('Generating daily reports...');
    const companies = await this.prisma.company.findMany();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (const company of companies) {
      await this.generateForCompany(company.id, today);
    }
  }

  async generateForCompany(companyId: string, date: Date) {
    const startOfDay = new Date(date);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    // Orders for this company: joined via employee->transporter, or simplified
    // here as "orders released today whose transporter belongs to this company".
    const employees = await this.prisma.employee.findMany({ where: { companyId }, select: { userId: true } });
    const employeeUserIds = employees.map((e) => e.userId);

    const orders = await this.prisma.order.findMany({
      where: {
        status: 'RELEASED',
        releasedAt: { gte: startOfDay, lte: endOfDay },
        transporterId: { in: employeeUserIds },
      },
      include: { listing: true, payments: true },
    });

    const revenueXaf = orders.reduce((sum, o) => sum + Number(o.totalPriceXaf), 0);
    const momoFeesXaf = orders.reduce((sum, o) => sum + Number(o.feeXaf), 0);
    const netXaf = revenueXaf - momoFeesXaf;

    const cropCounts = new Map<string, number>();
    for (const o of orders) {
      const crop = o.listing.cropType;
      cropCounts.set(crop, (cropCounts.get(crop) ?? 0) + 1);
    }
    const topCrop = [...cropCounts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] as any;

    const activeEmployeeCount = await this.prisma.shift.count({
      where: {
        employee: { companyId },
        clockIn: { gte: startOfDay, lte: endOfDay },
      },
    });

    return this.prisma.dailyReport.upsert({
      where: { companyId_reportDate: { companyId, reportDate: startOfDay } },
      update: { ordersCount: orders.length, revenueXaf, momoFeesXaf, netXaf, topCrop, activeEmployees: activeEmployeeCount },
      create: {
        companyId,
        reportDate: startOfDay,
        ordersCount: orders.length,
        revenueXaf,
        momoFeesXaf,
        netXaf,
        topCrop,
        activeEmployees: activeEmployeeCount,
      },
    });
  }

  getReports(companyId: string, from?: Date, to?: Date) {
    return this.prisma.dailyReport.findMany({
      where: {
        companyId,
        reportDate: { gte: from, lte: to },
      },
      orderBy: { reportDate: 'desc' },
    });
  }
}
