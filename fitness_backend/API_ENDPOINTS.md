# ModivFit API – Endpoints Reference

**Base URL:** `http://<host>:8000/api`  
**Auth:** Bearer token (Laravel Sanctum). Send header: `Authorization: Bearer <token>`  
**Content-Type:** `application/json` for JSON bodies; `multipart/form-data` for file uploads.

---

## Public (no auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/login` | Login (email, password) |
| POST | `/auth/login` | Same as `/login` |
| POST | `/auth/signin` | Same as `/login` |
| POST | `/register` | Register (name, email, password, optional: phone, gender, height, weight, fitness_level, goal, date_of_birth) |
| POST | `/auth/signup` | Same as `/register` |
| POST | `/send_otp` | Send OTP to email (body: `email`) |
| POST | `/auth/forgot-password` | Same as `/send_otp` |
| POST | `/auth/send-change-password-otp` | Same as `/send_otp` |
| POST | `/validate_otp` | Validate OTP (body: `email`, `otp`) |
| POST | `/auth/verify-signup-otp` | Same as `/validate_otp` |
| POST | `/auth/verify-forgot-otp` | Same as `/validate_otp` |
| POST | `/auth/verify-change-password-otp` | Same as `/validate_otp` |
| POST | `/update_password` | Set new password (body: `email`, `otp`, `new_password` or `password`) |
| POST | `/auth/reset-password` | Same as `/update_password` |
| POST | `/auth/change-password` | Same as `/update_password` |
| POST | `/auth/confirm-password` | Same as `/update_password` |

---

## Protected (require `Authorization: Bearer <token>`)

### Current user
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/user` | Get current user from token |

### Auth / session
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/token_login` | Same as `/user` |
| GET | `/logout` | Logout (invalidates token) |

### Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/user_profile` | Get current user profile |
| GET | `/profile` | Same as `/user_profile` |
| POST | `/update_profile` | Update profile (name, user_name/username, bio, fitness_level) |
| POST | `/profile` | Same as `/update_profile` |
| POST | `/update_profile_img` | Upload profile image (multipart: `image` or `media`) |
| POST | `/profile/image` | Same as `/update_profile_img` |
| GET | `/profile/media` | Get current user’s media (e.g. challenge media) |

### Onboarding
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/onboarding/save` | Save onboarding step (step data merged into profile) |
| GET | `/onboarding/get` | Same as `/user_profile` |

### Home
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/home` | Combined feed (challenges + food_logs for current user) |

### Challenges
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/challenges` | My challenges (created + accepted) |
| GET | `/my_challenges` | Same as `/challenges` |
| GET | `/all_challenges` | Public challenges (paginated) |
| GET | `/challenges/current` | Current active challenge |
| GET | `/challenges/categories` | List challenge categories |
| POST | `/challenges/start-random` | Get a random challenge |
| GET | `/challenges/limits` | Challenge limits |
| POST | `/challenges/limits/extend` | Extend limits |
| GET | `/challenges/cards` | Same as `/challenges` |
| GET | `/challenges/{id}` | Get one challenge by id |
| GET | `/challenges/{id}/progress` | Get progress for challenge |
| POST | `/challenges/{id}/progress` | Same (stub) |
| POST | `/challenges/{id}/record` | Record challenge progress |
| POST | `/create_challenge` | Create challenge (name/title, category, fitness_level, description, time, optional media file) |
| POST | `/accept_challenge` | Accept challenge (body: `user_id`, `challenge_id`) |
| POST | `/like_challenge` | Like a challenge |
| POST | `/comment` | Comment on challenge |
| POST | `/like_comment` | Like a comment |
| POST | `/like_accepted_challenge` | Like accepted challenge |
| POST | `/sub_comment` | Sub-comment |
| POST | `/like_sub_comment` | Like sub-comment |
| POST | `/accept_challenge_upload` | Upload for accepted challenge (stub) |

### Food logs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/create_food_log` | Create food log (description/message, optional: title, type, calories, protein, carbs, fats) |
| GET | `/my_food_logs` | Current user’s food logs |
| GET | `/all_food_logs` | Public food logs |
| POST | `/like_food_log` | Like food log (body: `food_log_id`) |
| POST | `/comment_food_log` | Comment on food log (body: `food_log_id`, description) |
| POST | `/like_food_log_comment` | Like food log comment |
| POST | `/delete_food_log` | Delete food log (body: `food_log_id`) |

### Media / posts
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/posts/media` | Upload media (multipart: image/video/media/file, optional caption, visibility, type) |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/get_contacts` | Chat rooms (contacts) for current user |
| GET | `/chat/rooms` | Same as `/get_contacts` |
| GET | `/chat/rooms/{roomId}/messages` | Messages in room |
| POST | `/chat/rooms/{roomId}/messages` | Send message (body: `message` or `content`) |
| POST | `/send_message` | Send message (body: `room_id` or `roomId`, `message`) |
| POST | `/chat/rooms/{roomId}/invite` | Invite to room (stub) |

### Friends / follow
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/friends/search` | Search users (query: `?q=...`) |
| POST | `/follow` | Follow user (body: `id` = user to follow) |
| POST | `/users/follow` | Same (body: `user_id` or `id`) |
| POST | `/users/{userId}/follow` | Follow user by path id |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | List notifications (query: `?unread=1` for unread only) |
| GET | `/notifications/unread-count` | Unread count |
| POST | `/notifications/{id}/read` | Mark one as read |
| POST | `/notifications/{id}/action` | Action on notification (body: `action`, e.g. `read`) |
| POST | `/notifications/read-all` | Mark all as read |
| POST | `/notifications/mark-all-read` | Same as read-all |

### Leaderboard & social
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/leaderboard` | Leaderboard (users by points) |
| POST | `/leaderboard` | Same |
| POST | `/social_detail` | Follower/following and total likes counts |

### Subscription
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/subscription` | Current subscription |
| GET | `/subscriptions` | Same |
| GET | `/subscriptions/plans` | Available plans |
| POST | `/subscriptions/checkout` | Checkout (stub) |
| POST | `/update_subscription` | Select/update subscription (body: plan, tier, etc.) |
| POST | `/subscription/select` | Same |
| POST | `/subscriptions/select` | Same |
| POST | `/subscription/plan` | Same |
| POST | `/subscriptions/plan` | Same |

### Settings
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/settings` | Get settings (stub: language, theme) |
| PUT | `/settings` | Update settings (stub) |
| PUT | `/settings/language` | Set language (stub) |
| PUT | `/settings/theme` | Set theme (stub) |

### Steps / fitness
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/steps/summary` | Steps summary (query: `?range=week`) |
| POST | `/fitness_record` | Same (POST) |
| POST | `/update_fitness_level` | Update user fitness level |

### Guides
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/guides` | Guides list (stub) |
| GET | `/guides/posts` | Guide posts (stub) |
| POST | `/guides/posts/{id}/like` | Like guide post (stub) |
| POST | `/guides/posts/{id}/reply` | Reply to guide post (stub) |

### Reels
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/reels/reactions` | Reels reactions (stub) |
| POST | `/reels/{reelId}/reactions` | Reactions for one reel (stub) |
| POST | `/reels/{reelId}/reactions/{type}` | Toggle reaction by type (stub) |

### Other
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/update_fcm` | Update FCM token (body: `fcm_token` or `fcm`) |
| POST | `/view_user_profile` | View another user profile (stub) |
| POST | `/add_recipe` | Add recipe (stub) |
| POST | `/get_recipes` | Get recipes (stub) |
| POST | `/add_steps` | Add steps (stub) |
| POST | `/report` | Report (stub) |
| POST | `/get_shorts` | Get shorts (stub) |
| POST | `/search_videos` | Search videos (stub) |

---

## Response format

- Success: `{ "success": true, "message": "...", "token"?: "...", "user"?: {...}, "data"?: {...} }`
- Error: `{ "success": false, "message": "..." }` or validation `errors` object.
- Paginated: Laravel pagination shape (`data`, `current_page`, `last_page`, etc.) or wrapper with `data`/`challenges`/`food_logs` etc.

## User object (from login / profile)

`id`, `name`, `email`, `user_name`, `username`, `bio`, `fitness_level`, `points`, `media`, `avatar_url`, `phone`, `country`, `gender`, `date_of_birth`.
