import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../common/prisma.module';

@Injectable()
export class EmployeesService {
  constructor(private prisma: PrismaService) {}

  async setPin(employeeId: string, pin: string) {
    if (!/^\d{4}$/.test(pin)) throw new BadRequestException('Le PIN doit contenir 4 chiffres');
    const pinCodeHash = await bcrypt.hash(pin, 10);
    return this.prisma.employee.update({ where: { id: employeeId }, data: { pinCodeHash } });
  }

  private async verifyPin(userId: string, pin: string) {
    const employee = await this.prisma.employee.findUnique({ where: { userId } });
    if (!employee) throw new UnauthorizedException('Employé introuvable');
    const ok = await bcrypt.compare(pin, employee.pinCodeHash);
    if (!ok) throw new UnauthorizedException('PIN incorrect');
    return employee;
  }

  async clockIn(userId: string, pin: string, lat: number, lng: number) {
    const employee = await this.verifyPin(userId, pin);

    const openShift = await this.prisma.shift.findFirst({
      where: { employeeId: employee.id, clockOut: null },
    });
    if (openShift) throw new BadRequestException('Un pointage est déjà en cours');

    const shift = await this.prisma.shift.create({
      data: { employeeId: employee.id, clockIn: new Date() },
    });
    await this.prisma.$executeRawUnsafe(
      `UPDATE shifts SET "clockInGps" = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
      lng,
      lat,
      shift.id,
    );
    return shift;
  }

  async clockOut(userId: string, pin: string, lat: number, lng: number) {
    const employee = await this.verifyPin(userId, pin);

    const openShift = await this.prisma.shift.findFirst({
      where: { employeeId: employee.id, clockOut: null },
      orderBy: { clockIn: 'desc' },
    });
    if (!openShift) throw new BadRequestException('Aucun pointage en cours');

    await this.prisma.shift.update({ where: { id: openShift.id }, data: { clockOut: new Date() } });
    await this.prisma.$executeRawUnsafe(
      `UPDATE shifts SET "clockOutGps" = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
      lng,
      lat,
      openShift.id,
    );
    return this.prisma.shift.findUnique({ where: { id: openShift.id } });
  }
}
