import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { EmployeesService } from './employees.service';

@UseGuards(AuthGuard('jwt'))
@Controller('employees')
export class EmployeesController {
  constructor(private employees: EmployeesService) {}

  @Post('clock-in')
  clockIn(@Req() req: any, @Body() body: { pin: string; lat: number; lng: number }) {
    return this.employees.clockIn(req.user.userId, body.pin, body.lat, body.lng);
  }

  @Post('clock-out')
  clockOut(@Req() req: any, @Body() body: { pin: string; lat: number; lng: number }) {
    return this.employees.clockOut(req.user.userId, body.pin, body.lat, body.lng);
  }
}
