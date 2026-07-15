import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ListingsService } from './listings.service';
import { CreateListingDto, SearchListingsDto } from './dto/listings.dto';

@Controller('listings')
export class ListingsController {
  constructor(private listings: ListingsService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  create(@Req() req: any, @Body() dto: CreateListingDto) {
    return this.listings.create(req.user.userId, dto);
  }

  @Get()
  search(@Query() q: SearchListingsDto) {
    return this.listings.search(q);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.listings.findOne(id);
  }
}
