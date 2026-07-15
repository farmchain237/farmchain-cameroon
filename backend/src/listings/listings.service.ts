import { Injectable } from '@nestjs/common';
import { PrismaService } from '../common/prisma.module';
import { CreateListingDto, SearchListingsDto } from './dto/listings.dto';

@Injectable()
export class ListingsService {
  constructor(private prisma: PrismaService) {}

  async create(farmerId: string, dto: CreateListingDto) {
    const listing = await this.prisma.listing.create({
      data: {
        farmerId,
        farmId: dto.farmId,
        cropType: dto.cropType,
        region: dto.region,
        qtyKg: dto.qtyKg,
        grade: dto.grade,
        pricePerKg: dto.pricePerKg,
        harvestDate: new Date(dto.harvestDate),
        photos: dto.photos,
      },
    });

    // Set PostGIS point via raw SQL since Prisma can't write Unsupported() columns directly
    if (dto.lat != null && dto.lng != null) {
      await this.prisma.$executeRawUnsafe(
        `UPDATE listings SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
        dto.lng,
        dto.lat,
        listing.id,
      );
    }

    return listing;
  }

  // Filtered + optional radius search. Falls back to plain filters if no lat/lng given
  // (essential for 2G/offline-first clients that can't always get a GPS fix instantly).
  async search(q: SearchListingsDto) {
    const page = q.page ?? 1;
    const pageSize = Math.min(q.pageSize ?? 20, 50);
    const offset = (page - 1) * pageSize;

    const conditions: string[] = [`status = 'ACTIVE'`];
    const params: any[] = [];
    let idx = 1;

    if (q.cropType) { conditions.push(`"cropType" = $${idx++}`); params.push(q.cropType); }
    if (q.region) { conditions.push(`region = $${idx++}`); params.push(q.region); }
    if (q.grade) { conditions.push(`grade = $${idx++}`); params.push(q.grade); }
    if (q.minPrice != null) { conditions.push(`"pricePerKg" >= $${idx++}`); params.push(q.minPrice); }
    if (q.maxPrice != null) { conditions.push(`"pricePerKg" <= $${idx++}`); params.push(q.maxPrice); }

    let distanceSelect = '';
    let orderBy = 'ORDER BY "createdAt" DESC';

    if (q.lat != null && q.lng != null) {
      distanceSelect = `, ST_Distance(location, ST_SetSRID(ST_MakePoint($${idx}, $${idx + 1}), 4326)::geography) / 1000 AS "distanceKm"`;
      const lngIdx = idx, latIdx = idx + 1;
      params.push(q.lng, q.lat);
      idx += 2;
      if (q.radiusKm) {
        conditions.push(
          `ST_DWithin(location, ST_SetSRID(ST_MakePoint($${lngIdx}, $${latIdx}), 4326)::geography, $${idx++})`,
        );
        params.push(q.radiusKm * 1000);
      }
      orderBy = `ORDER BY "distanceKm" ASC`;
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    params.push(pageSize, offset);

    const sql = `
      SELECT id, "farmerId", "cropType", region, "qtyKg", grade, "pricePerKg",
             "harvestDate", photos, "createdAt" ${distanceSelect}
      FROM listings
      ${where}
      ${orderBy}
      LIMIT $${idx++} OFFSET $${idx++}
    `;

    return this.prisma.$queryRawUnsafe(sql, ...params);
  }

  findOne(id: string) {
    return this.prisma.listing.findUnique({
      where: { id },
      include: { farmer: true, videos: true },
    });
  }
}
