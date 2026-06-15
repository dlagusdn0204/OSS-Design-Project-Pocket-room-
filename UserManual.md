<div align="center">

<br><br><br>

# 🏠 **Pocket Room**
**Pocket Room User Manual**

<br>

<img width="468" height="510" alt="image" src="https://github.com/user-attachments/assets/6bd60eee-ca92-4f49-a1cc-3a7b4ed26f13" />

<br><br>


| **Student No** | 22212047 |
| :---: | :---: |
| **Name** | 임현우 |
| **E-mail** | dlagusdn9182@gmail.com |
| **GitHub** | [repository](https://github.com/dlagusdn0204/OSS-Design-Project-Pocket-room-/tree/main) |

<br><br><br>

</div>

---

# **Revision history**
<br>

| Revision date | Version # | Description | Author |
| :---: | :---: | :---: | :--- |
| 06/15/2026 | 1.00 | First draft  | 임현우 |

<br>

---

# **Contents**

<pre style="display: inline-block; text-align: left; border: none; background: none;">
1. Introduction
2. User Manual
</pre>

<br><br><br>

# 1. Introduction

**1.1 Summary**

> 본 문서는 Pocket Room 어플의 android 버전 사용 설명서이다. 어플의 작동에 대한 사용 설명 및 예시 입력을 제시한다.

**1.2 Unimplemented**

> 이전 DESIGN PHASE에서 언급했듯 한전, 도시가스 측 공식 API에서 학술목적으로 정보를 제공하지 않기에 이는 PocketRoom 서버에서 공식 API에 연결할 준비만 하고 예시입력 및 예시 출력으로 동작만 확인한다.
>
> 계약서 이미지 스캔 기능 또한 구현의 한계로 우선 스캔 버튼을 누르면 자동으로 예시 입력이 작성되도록 동작만 확인한다.


<br><br><br>

---

# 2. Manual

**1. login**
<img width="1080" height="2400" alt="Screenshot_20260615_233124" src="https://github.com/user-attachments/assets/0b2a6093-bef0-487a-a4d2-09423b852ead" />
> 로그인 화면으로 회원가입이 된 아이디로 로그인이 가능하다.
>
> 자동 로그인 버튼으로 앱을 다시 키더라도 로그인 상태를 유지시킬 수 있다
>
> 회원가입 버튼으로 회원가입 할 수 있다.
>
> 회원가입 시 입력한 이메일로 아이디를 찾을 수 있다.
>
> 비밀번호를 잊어버렸다면 회원가입 시 입력한 이메일과 아이디로 비밀번호를 변경할 수 있다.

<br>

**2. singin**
<img width="1080" height="2400" alt="Screenshot_20260615_233135" src="https://github.com/user-attachments/assets/d1b6e70c-8178-4bba-992d-692465ec83df" />
<br><br>
<img width="1080" height="2400" alt="Screenshot_20260615_233241" src="https://github.com/user-attachments/assets/3f1b6e73-ab9d-4fee-b74d-d53308ac4d5d" />
> 로그인 화면에서 회원가입 버튼을 누르면 작동하는 회원가입 화면이다. 아이디 중복 확인 검증 후 회원가입 가능하다.

<br>

**3. addroom**
<img width="1080" height="2400" alt="Screenshot_20260615_233259" src="https://github.com/user-attachments/assets/2790cbaf-e93a-4846-af02-23b530b26ec1" />
>처음 로그인을 하게되면 이 화면이 나온다. '+방 추가하기' 버튼을 눌러서 방을 추가할 수 있다.
<img width="1080" height="2400" alt="Screenshot_20260615_233305" src="https://github.com/user-attachments/assets/c17a2a66-a6fa-4785-a6c6-15bd85be624c" />

> 방 이름을 적은 뒤 방을 생성할 수 있다.

<br>

**4. Card**
> 각 카드 설정의 동작을 설명한다.
<img width="1080" height="2400" alt="Screenshot_20260615_233321" src="https://github.com/user-attachments/assets/a05dfea7-c5db-4e43-ac98-17031d8ca51e" />
<img width="1080" height="2400" alt="Screenshot_20260615_233330" src="https://github.com/user-attachments/assets/b59baeea-06f9-415f-beec-43e394bc6eb0" />

> 월세 카드 설정이다. 정보를 직접 입력할 수도 있고 계약서 스캔을 통해 바로 정보를 채울 수 있다.
>
> 앞서 언급했듯 스캔은 아직 구현되지않았으므로 자동으로 예시정보를 채워 동작만 보여준다.
<img width="1080" height="2400" alt="Screenshot_20260615_233751" src="https://github.com/user-attachments/assets/1ccb1f57-16d7-4336-901d-4b2258a0257b" />

> 전기 카드 설정이다. 앞서 언급했듯 공식 API에서 학술목적으로 정보를 제공하지 않은 관계로 예시입력 '12345'를 입력하면 서버로부터 예시 정보를 받을 수 있다.
<img width="1080" height="2400" alt="Screenshot_20260615_233758" src="https://github.com/user-attachments/assets/bd8e0b85-b683-45f4-890d-9d69e6f163a4" />

> 도시가스 카드 설정이다. 앞서 언급했듯 공식 API에서 학술목적으로 정보를 제공하지 않은 관계로 도시가스 회사 선택 후 예시입력 '12345'를 입력하면 서버로부터 예시 정보를 받을 수 있다.

<br>

**5. main interface**
<img width="1080" height="2400" alt="Screenshot_20260615_233804" src="https://github.com/user-attachments/assets/2b20edce-b1c9-46d2-a738-62e73928baae" />
<img width="1080" height="2400" alt="Screenshot_20260615_233807" src="https://github.com/user-attachments/assets/1a0b0d76-b720-4f8b-8ac0-e8b3069540a1" />
>입력이 끝난 뒤 메인 화면이다.



