import 'package:manage_aura/model/enums.dart';
import 'package:manage_aura/model/product.dart';
import 'package:manage_aura/model/shop.dart';
import 'package:manage_aura/model/supplier.dart';
import 'package:manage_aura/service/stock_service.dart';

void main(){

  Shop shop = Shop("Socheata");

  StockService service = StockService(shop: shop);

  Product p1 = Product(id: '123', name: 'Iphone 7', sku: 'iph1237', price: 49);
  Product p2 = Product(id: '124', name: 'Iphone 8', sku: 'iph1238', price: 99);
  Product p3 = Product(id: '125', name: 'Iphone x', sku: 'iph123x', price: 119);

  service.addProduct(p1);
  service.addProduct(p2);
  service.addProduct(p3);

  
  print(service.getProduct('123'));

}