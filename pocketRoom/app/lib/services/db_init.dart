// DB 초기화 분기 — 플랫폼에 따라 알맞은 설정을 고릅니다.
//
// 왜 필요한가?
//   기본 sqflite 는 iOS/Android(네이티브)에서만 동작합니다.
//   Chrome(웹)에서 미리보기하려면 sqflite_common_ffi_web 으로 갈아끼워야 합니다.
//   아래 "조건부 import"는 웹에서 빌드될 때만 _web 파일을, 그 외에는 _native 파일을
//   사용하도록 컴파일러가 자동으로 골라줍니다. (한쪽 코드가 다른 플랫폼을 깨뜨리지 않게)
//
// 사용법: main() 에서 initDbFactory() 를 한 번 호출하면 됩니다.

export 'db_init_native.dart'
    if (dart.library.html) 'db_init_web.dart';
