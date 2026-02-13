# 작업 기록

## 2026-02-07 - concept2_race_spec.md 분석 및 전체 구현
- concept2_race_spec.md 파일 분석하여 필요한 라이브러리 설치 및 전체 앱 구현
- Concept2 PM5 다중 BLE 연결 실시간 레이스 디스플레이 앱
- Riverpod 상태관리, flutter_blue_plus BLE 통신
- 5개 화면: 거리설정, 기기연결, 대기, 레이스, 결과

## 2026-02-07 16:00 - 불필요한 주석 제거
- 프로젝트 전체 dart 파일에서 불필요한 주석 제거

## 2026-02-08 - image_gallery_saver_plus 빌드 에러 수정
- image_gallery_saver_plus가 Flutter v1 Registrar API 사용하여 빌드 실패
- gal 패키지로 교체하여 해결

## 2026-02-08 14:00 - 이미지 저장 시 1MB 이하로 압축
- screenshot_service.dart에 이미지 압축 로직 추가
- PNG → JPEG 변환 후 quality 조절하여 1MB 이하로 압축
- image 패키지 추가

## 2026-02-08 16:00 - 사진첩 권한 요청 및 거부 시 설정 이동 alert 추가
- 처음 사진첩 접근 시 Gal 패키지로 권한 요청
- 권한 거부 시 설정 이동 안내 AlertDialog 추가
- iOS Info.plist에 NSPhotoLibraryAddUsageDescription 추가

## 2026-02-08 15:00 - 디자인 컨셉 3가지 HTML 프로토타입 제작
- 컨셉1: Dark Stadium (다크 스타디움/전광판) - design_concept_1_dark_stadium.html
- 컨셉2: Nautical (항해/마린) - design_concept_2_nautical.html
- 컨셉3: Olympic Broadcast (올림픽 중계) - design_concept_3_olympic.html

## 2026-02-13 14:00 - 레이스 플로우 변경 및 카운트다운 추가
- 완주 시간을 레이스 시작 후 경과 시간으로 변경 (기계 데이터는 별도 저장)
- 5초 카운트다운 오버레이 추가 (딤 처리 전체화면)
- 플로우 변경: 기기연결 → 워밍업(0m확인) → 레이스 시작 → 카운트다운 → 즉시 시작
- 모든 PM5 기기 0m 리셋 확인 전 시작 버튼 비활성화
- 로잉 감지 대기 제거, 카운트다운 후 즉시 레이스 시작

## 2026-02-13 10:00 - easy_localization 다국어 처리 구현
- easy_localization 패키지 추가하여 앱 전체 다국어 지원
- 지원 언어: 한국어(기본), 영어, 일본어, 스페인어
- 50+ 번역 키를 JSON 파일로 관리 (assets/translations/)
- 모든 화면/위젯/모델/서비스의 하드코딩 문자열을 .tr()로 변환
- 거리 설정 화면에 언어 전환 UI 추가

## 2026-02-13 17:00 - Google Fonts 오프라인 번들링
- google_fonts 런타임 다운로드 실패 오류 수정 (fonts.gstatic.com 접속 불가)
- 5개 폰트 파일 로컬 다운로드: BebasNeue, BarlowCondensed(Bold/SemiBold), Barlow, IBMPlexMono
- google_fonts/ 디렉토리에 .ttf 번들링, pubspec.yaml assets 등록
- GoogleFonts.config.allowRuntimeFetching = false 설정

## 2026-02-13 16:00 - BLE 연결 안정성 강화 + 코드 분석
- Characteristic 구독 메모리 누수 수정 (onValueReceived 구독 저장/정리)
- 레이스 모드 추가: 카운트다운~레이스 중 무제한 재연결, 짧은 간격(300ms→1s→2s)
- requestConnectionPriority(high) 레이스 중 자동 호출
- 데이터 타임아웃 3초→5초(일반)/8초(레이스) 증가
- 레이스 레인 위젯에 BLE 연결 끊김 경고 표시 (깜빡이는 블루투스 아이콘 + 빨간 스트라이프)
- UI 테스트(widget_test.dart) 제거
- 기존 테스트 수정 (race_config_test, ble_device_state_test)

## 2026-02-08 17:00 - Olympic Broadcast 디자인 컨셉 Flutter 앱 적용
- google_fonts 패키지 추가 (Bebas Neue, Barlow Condensed, IBM Plex Mono)
- lib/theme/app_theme.dart 신규 생성 (OlympicColors, OlympicTextStyles, AppTheme, CustomClippers)
- 다크 테마 전환 (charcoal 배경, Olympic Red/Blue 액센트)
- 전체 5개 화면 + 2개 위젯 Olympic Broadcast 스타일로 전면 재설계
- 레이스 화면: ClipPath 경사 헤더, LIVE 인디케이터, 대각선 스트라이프 오버레이
- 레인 위젯: 좌측 컬러 스트라이프, Bebas Neue 순위(1ST/2ND), 프로그레스 바, stat 칩
- 결과 화면: gold/silver/bronze medal stripe, 1위 glow 효과
