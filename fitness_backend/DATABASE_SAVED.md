# What Is Saved in the Database (ModivFit Backend)

This document lists every **table** and the **fields** that are persisted when your API is used. File uploads (e.g. profile image, challenge media) are stored on **disk** (`storage/app/public/...`); only the **path** is saved in the database.

---

## 1. `users`

| Column | Saved when / meaning |
|--------|----------------------|
| id | Auto. |
| name | Register, update profile. |
| email | Register (unique). |
| email_verified_at | Optional verification. |
| password | Register (hashed). |
| phone | Register / update (optional). |
| height | Register / onboarding (optional). |
| weight | Register / onboarding (optional). |
| fitness_level | Register / onboarding / update profile (optional). |
| goal | Register (optional). |
| points | Default 0; can be updated by your logic. |
| date_of_birth | Register (optional). |
| gender | Register (optional). |
| fcm_token | FCM update endpoint (optional). |
| media | Profile image **path** after upload (e.g. `avatars/xyz.jpg`). |
| user_name | Auto-generated on register; update profile. |
| country | Register (optional). |
| login_type | Default `email`. |
| bio | Update profile (optional). |
| remember_token | Laravel. |
| created_at, updated_at | Auto. |

**Also created by Laravel:** `password_reset_tokens`, `sessions` (session data).

---

## 2. `personal_access_tokens`

Laravel Sanctum: one row per login token.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| tokenable_type, tokenable_id | User (morph). |
| name | e.g. `auth_token`. |
| token | Hashed token. |
| abilities | Null or permissions. |
| last_used_at, expires_at | Optional. |
| created_at, updated_at | Auto. |

**Saved when:** User logs in (`login` / `register`). Deleted when user logs out.

---

## 3. `challenges`

| Column | Saved when / meaning |
|--------|----------------------|
| id | Auto. |
| user_id | Creator (from auth). |
| title | Create challenge. |
| description | Create challenge. |
| time | Create challenge (optional). |
| media | **Path** to uploaded image/video (optional). |
| category | Create challenge (optional). |
| level | Create challenge (e.g. fitness_level). |
| created_at, updated_at | Auto. |

**Saved when:** `POST create_challenge` (and when creating a challenge via API).

---

## 4. `accepted_challenges`

| Column | Saved when / meaning |
|--------|----------------------|
| id | Auto. |
| user_id | User who accepted. |
| challenge_id | Challenge accepted. |
| level, description, time | Optional progress. |
| reports | Default 0. |
| media | Upload for accepted challenge (optional). |
| status | e.g. `active`. |
| media_upload_time | Optional. |
| type | e.g. `public`. |
| points_awarded | Boolean, default false. |
| created_at, updated_at | Auto. |

**Saved when:** User accepts a challenge (`accept_challenge`).

---

## 5. `comments`

Comments on **challenges**.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Commenter. |
| challenge_id | Challenge. |
| description | Comment text. |
| created_at, updated_at | Auto. |

**Saved when:** `POST comment` (challenge comment).

---

## 6. `sub_comments`

Replies to challenge comments.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Author. |
| comment_id | Parent comment. |
| description | Reply text. |
| created_at, updated_at | Auto. |

**Saved when:** Sub-comment endpoint (e.g. `sub_comment`).

---

## 7. `challenge_likes`

Likes on **challenges**.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| challenge_id | Challenge. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_challenge`.

---

## 8. `accepted_challenges_likes`

Likes on **accepted challenges**.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| accepted_challenge_id | Accepted challenge. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_accepted_challenge`.

---

## 9. `comments_likes`

Likes on **challenge comments**.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| comment_id | Comment. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_comment`.

---

## 10. `sub_comments_likes`

Likes on **sub-comments**.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| sub_comment_id | Sub-comment. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_sub_comment`.

---

## 11. `followers`

Follow relationship: `follower_id` follows `followed_id`.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| followed_id | User being followed. |
| follower_id | User who follows. |
| created_at, updated_at | Auto. |

**Saved when:** `POST follow` (or `users/follow`). **Deleted when:** Unfollow (toggle).

---

## 12. `verifications`

OTP / email verification (e.g. forgot password, signup verify).

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Optional (nullable). |
| email | Email the OTP was sent to. |
| verification_code | OTP code. |
| token | Optional type/token. |
| expires_at | Expiry time. |
| created_at, updated_at | Auto. |

**Saved when:** `POST send_otp` / `auth/forgot-password` etc. Typically **deleted** after successful `validate_otp` + `update_password`.

---

## 13. `food_logs`

User food / meal logs.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Owner. |
| title | Optional. |
| type | Optional. |
| calories, protein, carbs, fats | Optional numbers. |
| description | Text (or message). |
| created_at, updated_at | Auto. |

**Saved when:** `POST create_food_log`.

---

## 14. `food_logs_likes`

Likes on food logs.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| food_log_id | Food log. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_food_log`.

---

## 15. `food_log_comments`

Comments on food logs.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Commenter. |
| food_log_id | Food log. |
| description | Comment text. |
| created_at, updated_at | Auto. |

**Saved when:** `POST comment_food_log`.

---

## 16. `food_log_comments_likes`

Likes on food log comments.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Who liked. |
| food_log_comment_id | Food log comment. |
| type | e.g. `like`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST like_food_log_comment`.

---

## 17. `chats`

Chat room per user + challenge (created when user creates or accepts a challenge).

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Participant. |
| challenge_id | Linked challenge. |
| is_admin | Creator vs accepter. |
| created_at, updated_at | Auto. |

**Saved when:** Creating a challenge or accepting a challenge.

---

## 18. `chat_messages`

Messages in a chat.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| sender_id | User who sent. |
| challenge_id | Challenge (room context). |
| chat_id | Chat room. |
| message | Text. |
| media | Optional media path. |
| message_type | Optional. |
| created_at, updated_at | Auto. |

**Saved when:** `POST send_message` / `POST chat/rooms/{roomId}/messages`.

---

## 19. `subscriptions`

User subscription state.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | User. |
| duration | e.g. `basic`, `premium`. |
| start_date, end_date, date | Optional dates. |
| status | e.g. `active`, `inactive`. |
| created_at, updated_at | Auto. |

**Saved when:** `POST update_subscription` / `subscription/select` / `subscriptions/select` / `subscription/plan` / `subscriptions/plan`.

---

## 20. `notifications`

In-app notifications for a user.

| Column | Meaning |
|--------|--------|
| id | Auto. |
| user_id | Recipient. |
| title | Optional. |
| description | Body text. |
| read_at | When read (null = unread). |
| created_at, updated_at | Auto. |

**Saved when:** Your app creates a notification (e.g. from a controller or job). **Updated when:** Mark as read (`notifications/{id}/read`, `notifications/mark-all-read`).

---

## Laravel system tables (also in DB)

- **cache** – Cache store (if using database driver).
- **jobs** – Queued jobs (if using database queue).
- **password_reset_tokens** – Legacy password reset tokens.
- **sessions** – Session data (if using database sessions).

---

## Not stored in DB (files only)

- **Profile images:** Stored under `storage/app/public/avatars/`; path in `users.media`.
- **Challenge media:** Stored under `storage/app/public/challenges/`; path in `challenges.media`.
- **Posts/media uploads:** Stored under `storage/app/public/media/`; path can be returned in API response (optional to store in a table later).

---

## Summary table

| Table | What is saved |
|-------|----------------|
| users | Account, profile, avatar path, fitness data, points |
| personal_access_tokens | Login tokens (Sanctum) |
| challenges | Created challenges (title, description, media path, category, level) |
| accepted_challenges | User acceptances and progress |
| comments | Challenge comments |
| sub_comments | Replies to challenge comments |
| challenge_likes | Likes on challenges |
| accepted_challenges_likes | Likes on accepted challenges |
| comments_likes | Likes on comments |
| sub_comments_likes | Likes on sub-comments |
| followers | Who follows whom |
| verifications | OTP codes (email, code, expiry) |
| food_logs | Food/meal logs (title, type, calories, description, etc.) |
| food_logs_likes | Likes on food logs |
| food_log_comments | Comments on food logs |
| food_log_comments_likes | Likes on food log comments |
| chats | Chat rooms (user + challenge) |
| chat_messages | Chat messages |
| subscriptions | User subscription (duration, status, dates) |
| notifications | In-app notifications (title, description, read_at) |

All of the above are **persisted in the database** when the corresponding API actions are performed. Media files themselves are on **disk**; only **paths** (and optional metadata) are in the DB.
