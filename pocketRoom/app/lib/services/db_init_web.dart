// 웹(Chrome) DB 초기화 — sqflite 를 웹용 구현(IndexedDB 기반)으로 교체합니다.
// 이 파일은 웹으로 빌드될 때만 사용됩니다(db_init.dart 의 조건부 import 참고).

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void initDbFactory() {
  // sqflite 의 기본 저장소를 "웹용 팩토리"로 바꿉니다.
  // 이렇게 하면 storage_service.dart 의 코드는 그대로 두고 웹에서도 DB가 동작합니다.
  databaseFactory = databaseFactoryFfiWeb;
}
