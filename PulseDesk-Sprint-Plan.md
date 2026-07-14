# PulseDesk — Kế Hoạch Sprint & Git Flow Chi Tiết

**AI-Powered Multi-Tenant Customer Support & Feedback Analytics SaaS (Ruby on Rails)**
Mục tiêu: hoàn thiện project trong ~8-9 ngày, thể hiện multi-tenant architecture + AI integration + SQL/OOP/concurrency — fit toàn bộ JD Ruby on Rails Intern và show business value thật.

---

## 0. Git Workflow Strategy

Dùng **Git Flow** (đồng nhất với TutorHub và các project Java trước đó):

```
master              → version đã deploy, ổn định
  └── develop        → nhánh tích hợp chính
        ├── feature/*    → mỗi task/feature riêng
        ├── release/*    → chuẩn bị release
        └── hotfix/*      → sửa gấp sau deploy
```

**Quy tắc:**
- Không code trực tiếp trên `develop`/`master`.
- Feature branch merge về `develop` qua PR (self-review), squash commit vụn.
- Naming: `feature/<sprint-so>-<ten-task>` (vd: `feature/s1-tenant-scoping`).
- Commit theo Conventional Commits: `feat:`, `fix:`, `chore:`, `test:`, `docs:`, `perf:`.
- Cuối mỗi sprint: tag `v0.x` trên `develop`.

---

## 1. Sprint 0 — Setup & Multi-Tenant Foundation (Ngày 1-2)

**Mục tiêu:** Khởi tạo project, thiết kế schema multi-tenant, đặt nền `TenantScoped` — đây là phần kiến trúc quan trọng nhất, làm sai từ đầu sẽ phải sửa lại toàn bộ về sau.

**Branch:** `feature/s0-project-setup` → `feature/s1-tenant-scoping`

### 1a. Setup (`feature/s0-project-setup`)
- [ ] `rails new pulsedesk -d postgresql --css=tailwind`
- [ ] `.gitignore`, `README.md` khung sườn
- [ ] Setup RSpec, factory_bot, faker, Rubocop
- [ ] Setup Sidekiq + Redis (cần cho AI job async ở Sprint 3)
- [ ] Vẽ ERD 7 bảng: `accounts`, `users`, `customers`, `tickets`, `ticket_messages`, `tags`, `ticket_tags`
- [ ] `TASKS.md` — breakdown + estimate giờ từng sprint (bằng chứng "estimate tasks" cho JD)

### 1b. Tenant Scoping (`feature/s1-tenant-scoping`)
- [ ] Migration `accounts` (company_name, plan, subdomain)
- [ ] Migration `users` với `account_id` FK — auth scoped theo tenant (`has_secure_password`)
- [ ] **Concern `TenantScoped`** (centerpiece kiến trúc):
  ```ruby
  module TenantScoped
    extend ActiveSupport::Concern
    included do
      belongs_to :account
      default_scope { where(account_id: Current.account&.id) }
    end
  end
  ```
  Dùng `ActiveSupport::CurrentAttributes` (`Current.account`) set ở `ApplicationController` mỗi request — tránh phải truyền `account_id` thủ công khắp nơi, đồng thời chống leak data giữa các tenant (lỗi bảo mật nghiêm trọng nhất nếu làm multi-tenant sai)
- [ ] Test riêng: viết spec chứng minh **tenant A không thể query được data của tenant B** dù cùng bảng — đây là test quan trọng nhất của cả project, nên show rõ trong report

### Definition of Done
- Đăng ký được nhiều account, mỗi account có users riêng
- Test tenant isolation pass 100%

### Git commands
```bash
git checkout -b develop
git checkout -b feature/s0-project-setup
git commit -m "chore: initial rails app setup with postgresql, sidekiq, rspec"
git checkout develop && git merge --no-ff feature/s0-project-setup

git checkout -b feature/s1-tenant-scoping
git commit -m "feat: add account and user models with tenant auth"
git commit -m "feat: add TenantScoped concern with Current.account pattern"
git commit -m "test: verify tenant data isolation across accounts"
git checkout develop && git merge --no-ff feature/s1-tenant-scoping
git tag v0.1
```

---

## 2. Sprint 1 — Ticket Core & Conversation Thread (Ngày 3-4)

**Mục tiêu:** CRUD ticket + hội thoại nhiều lượt, đúng use case support desk thật.

**Branch:** `feature/s2-tickets` → `feature/s3-ticket-messages`

### 2a. Tickets (`feature/s2-tickets`)
- [ ] Migration `customers` (account_id, name, email — end-user của tenant, không phải `users`)
- [ ] Migration `tickets` (account_id, customer_id, assigned_to, subject, status enum, priority enum)
- [ ] Include `TenantScoped` vào `Ticket`, `Customer`
- [ ] `TicketsController`: CRUD scoped tự động qua `Current.account`
- [ ] Composite index `(account_id, status)`, `(account_id, created_at)` — chuẩn bị cho query dashboard ở Sprint 3
- [ ] View: inbox-style list ticket (giống UI Zendesk/Intercom đơn giản hoá)

### 2b. Ticket Messages (`feature/s3-ticket-messages`)
- [ ] Migration `ticket_messages` (ticket_id, sender_type: customer/agent, body, created_at)
- [ ] View thread hội thoại trong ticket detail (ERB + CSS, giống chat UI)
- [ ] `tags` + `ticket_tags` (many-to-many, `has_many :through`)

### Definition of Done
- Tạo ticket, thêm message vào thread, gắn tag — tất cả scoped đúng theo tenant đang login

### Git commands
```bash
git checkout develop
git checkout -b feature/s2-tickets
git commit -m "feat: add customer and ticket models with tenant scoping"
git commit -m "feat: add composite indexes for dashboard query performance"
git checkout develop && git merge --no-ff feature/s2-tickets

git checkout -b feature/s3-ticket-messages
git commit -m "feat: add ticket_messages with conversation thread view"
git commit -m "feat: add tags with has_many_through ticket_tags"
git checkout develop && git merge --no-ff feature/s3-ticket-messages
git tag v0.2
```

---

## 3. Sprint 2 — AI Classification qua Background Job (Ngày 5, phần trọng tâm khác biệt)

**Mục tiêu:** Đây là phần không ai trong đám ứng viên Rails intern khác có — tích hợp LLM để tự động tóm tắt/chấm sentiment/gợi ý priority, chạy async qua Sidekiq.

**Branch:** `feature/s4-ai-classification`

### Tasks
- [ ] Thêm cột `ai_summary`, `sentiment_score`, `ai_suggested_priority` vào `tickets`
- [ ] `TicketClassifierService` (PORO, service object):
  ```ruby
  class TicketClassifierService
    def initialize(ticket)
      @ticket = ticket
    end

    def call
      response = call_llm_api(@ticket.messages_text)
      @ticket.update!(
        ai_summary: response[:summary],
        sentiment_score: response[:sentiment],
        ai_suggested_priority: response[:priority]
      )
    end
  end
  ```
  Gọi LLM API (OpenRouter/Groq — tái dùng pattern key/config từ cv-analyzer) yêu cầu trả về JSON có cấu trúc (summary, sentiment -1..1, priority)
- [ ] `TicketClassificationJob < ApplicationJob` — enqueue qua Sidekiq mỗi khi ticket mới tạo hoặc có message mới, **không block request** (đúng chuẩn production, khác hẳn gọi API đồng bộ)
- [ ] Xử lý lỗi: rescue timeout/rate-limit từ LLM API, retry với backoff (Sidekiq built-in), fallback nếu AI fail thì ticket vẫn hoạt động bình thường (graceful degradation — điểm cộng lớn khi giải thích trong phỏng vấn)
- [ ] View: hiển thị AI summary + sentiment badge (màu theo mức độ) trên ticket list
- [ ] RSpec: mock LLM response, test job enqueue đúng, test graceful fallback khi API lỗi

### Definition of Done
- Ticket mới tạo → job chạy async → summary/sentiment xuất hiện trong vài giây mà không cần reload đồng bộ
- App vẫn chạy bình thường nếu tắt AI API (fallback)

### Git commands
```bash
git checkout develop
git checkout -b feature/s4-ai-classification
git commit -m "feat: add ai_summary, sentiment_score columns to tickets"
git commit -m "feat: implement TicketClassifierService calling LLM API"
git commit -m "feat: add async TicketClassificationJob via sidekiq"
git commit -m "feat: add graceful fallback when AI api fails"
git commit -m "test: mock llm response and verify job enqueue behavior"
git checkout develop && git merge --no-ff feature/s4-ai-classification
git tag v0.3
```

---

## 4. Sprint 3 — Analytics Dashboard bằng Raw SQL (Ngày 6-7)

**Mục tiêu:** Show tay nghề SQL thật, tất cả query đều phải scoped theo tenant (khó hơn query đơn giản, chứng minh hiểu multi-tenant sâu).

**Branch:** `feature/s5-analytics` → `feature/s6-assignment-locking`

### 4a. Analytics (`feature/s5-analytics`)
- [ ] Query 1: Thời gian phản hồi trung bình theo agent (raw SQL, `JOIN` ticket + ticket_messages, tính delta timestamp, scoped `account_id`)
- [ ] Query 2: Xu hướng sentiment theo tuần (window function `AVG() OVER`, `GROUP BY` theo tuần)
- [ ] Query 3: Top tag phổ biến theo account (`GROUP BY`, `COUNT`, `ORDER BY` — qua bảng join `ticket_tags`)
- [ ] Đặt trong class `AnalyticsQuery` riêng (không nhét vào controller), luôn nhận `account_id` làm tham số bắt buộc — tránh bug leak data
- [ ] View: dashboard admin dùng Chartkick/Chart.js hiển thị 3 report trên

### 4b. Assignment & Locking (`feature/s6-assignment-locking`)
- [ ] `AssignmentService`: assign ticket cho agent bằng **pessimistic locking** (`Ticket.lock.find(id)`) — chống 2 agent nhận trùng 1 ticket khi bấm "Claim" cùng lúc
- [ ] `EscalationPolicy` (PORO): tự động nâng priority nếu ticket quá X giờ chưa phản hồi (business rule đơn giản, show OOP tách logic khỏi model)
- [ ] Test concurrency: giả lập 2 request claim cùng 1 ticket → chỉ 1 thành công

### Definition of Done
- Dashboard hiển thị đúng 3 report, tất cả scoped đúng tenant khi test với ≥2 account demo
- Test concurrency assignment pass

### Git commands
```bash
git checkout develop
git checkout -b feature/s5-analytics
git commit -m "feat: add AnalyticsQuery class with raw sql response time report"
git commit -m "feat: add sentiment trend query using window function"
git commit -m "feat: add top tags report and dashboard view with charts"
git checkout develop && git merge --no-ff feature/s5-analytics

git checkout -b feature/s6-assignment-locking
git commit -m "feat: implement AssignmentService with pessimistic locking"
git commit -m "feat: add EscalationPolicy for auto priority upgrade"
git commit -m "test: add concurrency spec for ticket claim race condition"
git checkout develop && git merge --no-ff feature/s6-assignment-locking
git tag v0.4
```

---

## 5. Sprint 4 — Testing, Polish & Deploy (Ngày 8-9)

**Mục tiêu:** Hoàn thiện test coverage, seed nhiều tenant demo, deploy live.

**Branch:** `feature/s7-testing` → `release/v1.0`

### Tasks
- [ ] RSpec request specs: full flow tạo ticket → AI classify → assign → resolve
- [ ] Seed data (`db/seeds.rb`): ít nhất **2-3 account/tenant khác nhau**, mỗi account có customer/ticket riêng — để demo trực tiếp tính năng tenant isolation cho interviewer thấy bằng mắt
- [ ] CSS polish: dashboard, inbox, ticket detail — responsive cơ bản
- [ ] `README.md` hoàn chỉnh: kiến trúc multi-tenant, ERD, luồng AI job, cách chạy local (kèm hướng dẫn set API key LLM), link demo
- [ ] GitHub Actions: chạy RSpec + Rubocop mỗi push
- [ ] Deploy Render/Fly.io (kèm Redis add-on cho Sidekiq)

### Release flow
```bash
git checkout develop
git checkout -b feature/s7-testing
git commit -m "test: add request specs for full ticket lifecycle"
git commit -m "chore: add multi-tenant seed data for demo"
git commit -m "docs: complete readme with architecture and ai flow explanation"
git commit -m "ci: add github actions for rspec and rubocop"
git checkout develop && git merge --no-ff feature/s7-testing

git checkout -b release/v1.0 develop
# smoke test cuối, fix nhỏ
git checkout master && git merge --no-ff release/v1.0
git tag v1.0
git checkout develop && git merge --no-ff release/v1.0
git branch -d release/v1.0
```

### Definition of Done
- App live, seed sẵn 2-3 tenant demo được ngay khi interviewer xem
- README đủ rõ để clone và chạy trong 5 phút
- CI xanh

---

## 6. Tổng Kết Mapping JD ↔ Sprint

| JD Requirement | Sprint tương ứng |
|---|---|
| HTML, CSS | Sprint 1 (inbox UI), Sprint 3 (dashboard chart), Sprint 4 (polish) |
| OOP | Sprint 0 (`TenantScoped` concern), Sprint 2 (`TicketClassifierService`), Sprint 3 (`AssignmentService`, `EscalationPolicy`) |
| Database | Sprint 0 (multi-tenant schema, ERD), composite index Sprint 1 |
| SQL (big plus) | Sprint 3 (3 raw SQL report, tenant-scoped) |
| Concurrency | Sprint 3 (pessimistic locking khi assign ticket) |
| Ruby/Rails ecosystem | Sidekiq + Redis (Sprint 0, 2), ActiveJob, `CurrentAttributes` |
| Git | Toàn bộ, Git Flow xuyên suốt |
| Estimate tasks | Sprint 0 (`TASKS.md`) |
| Business value | Toàn bộ concept — pitch được như sản phẩm thật, không chỉ bài tập |

## 7. Timeline Tổng Quan

| Sprint | Ngày | Nhánh chính | Tag |
|---|---|---|---|
| Sprint 0 | 1-2 | `feature/s0-project-setup`, `feature/s1-tenant-scoping` | v0.1 |
| Sprint 1 | 3-4 | `feature/s2-tickets`, `feature/s3-ticket-messages` | v0.2 |
| Sprint 2 | 5 | `feature/s4-ai-classification` | v0.3 |
| Sprint 3 | 6-7 | `feature/s5-analytics`, `feature/s6-assignment-locking` | v0.4 |
| Sprint 4 | 8-9 | `feature/s7-testing`, `release/v1.0` | v1.0 |

---

## 8. Câu chuyện phỏng vấn (chuẩn bị sẵn)

Khi được hỏi "kể về project Rails của em", nên trả lời theo cấu trúc:

1. **Vấn đề business:** SME cần công cụ theo dõi customer support mà không trả $50+/tháng cho Zendesk/Intercom.
2. **Quyết định kiến trúc khó nhất:** chọn multi-tenant với `default_scope` + `CurrentAttributes` thay vì tách database riêng cho mỗi tenant — đánh đổi giữa đơn giản vận hành và rủi ro leak data, và cách mình test để đảm bảo an toàn.
3. **Phần kỹ thuật tự hào nhất:** AI classification chạy async qua Sidekiq, có graceful fallback — không để 1 API bên thứ 3 chết làm sập cả app.
4. **Nếu có thêm thời gian sẽ làm gì:** tách theo schema-per-tenant nếu scale lớn, thêm ActionCable cho real-time ticket update.

Cấu trúc trả lời này show tư duy senior hơn hẳn "tôi đã làm CRUD" — đúng thứ để lại ấn tượng cho interviewer dù đang apply vị trí intern.

---

**Lưu ý:** Nếu deadline gấp, có thể gộp Sprint 0+1 (tenant scoping là phần không được cắt, đây là linh hồn của project) và rút gọn Sprint 3 xuống còn 1 report SQL thay vì 3, còn ~6 ngày. Sprint 2 (AI classification) là phần **không nên bỏ** vì đây là yếu tố khác biệt duy nhất so với 90% ứng viên khác.
