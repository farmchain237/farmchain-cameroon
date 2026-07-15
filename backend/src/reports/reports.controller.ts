import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ReportsService } from './reports.service';

@UseGuards(AuthGuard('jwt'))
@Controller('reports')
export class ReportsController {
  constructor(private reports: ReportsService) {}

  @Get('company/:companyId')
  get(
    @Param('companyId') companyId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.reports.getReports(companyId, from ? new Date(from) : undefined, to ? new Date(to) : undefined);
  }

  // TODO: /reports/company/:id/export?format=pdf|xlsx — pipe getReports() output through
  // a PDF (pdfkit) or Excel (exceljs) renderer, then email/WhatsApp via Twilio as specced.
}
