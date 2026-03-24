# What to Give the Frontend Developer

Use this as a checklist when handing off the backend to the frontend team.

---

## 1. Base URL and environment

- **Base URL:** `http://<host>:8000`
- **API prefix:** All endpoints live under `/api` (e.g. `http://<host>:8000/api/login`).
- For local dev, replace `<host>` with your machine IP or `localhost` (e.g. `http://192.168.2.107:8000` or `http://localhost:8000`).
- Frontend should use one configurable base URL (e.g. env variable) so it’s easy to switch between local/staging/production.

---

## 2. API documentation

- **Give them:** `API_ENDPOINTS.md` (in this project root).
- It lists every endpoint, method, and short description.
- They can use it to wire each screen/feature to the correct URL and payload.

---

## 3. Authentication

- **Login:** `POST /api/login` (or `POST /api/auth/login` / `POST /api/auth/signin`).
  - Body: `{ "email": "...", "password": "..." }`
  - Response: `{ "success": true, "token": "<bearer_token>", "user": { ... } }`
- **Register:** `POST /api/register` (or `POST /api/auth/signup`).
  - Body: `name`, `email`, `password`; optional: `phone`, `number`, `gender`, `height`, `weight`, `fitness_level`, `goal`, `date_of_birth`
  - Response: same shape with `token` and `user`.
- **Using the token:** For every protected request, send header:
  - `Authorization: Bearer <token>`
- **Current user:** `GET /api/user` with Bearer token returns the logged-in user.
- **Logout:** `GET /api/logout` with Bearer token (invalidates token on server).

Tell the frontend to:
- Store the token securely (e.g. secure storage / keychain).
- Send `Authorization: Bearer <token>` on all requests except login/register and the public auth endpoints (send OTP, validate OTP, update password).

---

## 4. Password reset / OTP flow

- Send OTP: `POST /api/send_otp` or `POST /api/auth/forgot-password` with `{ "email": "..." }`.
- Validate OTP: `POST /api/validate_otp` or `POST /api/auth/verify-forgot-otp` with `{ "email": "...", "otp": "..." }`.
- Set new password: `POST /api/update_password` or `POST /api/auth/reset-password` with `{ "email": "...", "otp": "...", "new_password": "..." }` (or `password` instead of `new_password`).

---

## 5. Request/response conventions

- **JSON:** Use `Content-Type: application/json` and `Accept: application/json` for JSON APIs.
- **File uploads:** Use `multipart/form-data` (e.g. profile image: field `image` or `media`; posts/media: `image` / `video` / `media` / `file`).
- **Success:** Responses usually include `success: true`, `message`, and often `user` or `data`.
- **Errors:** `success: false`, `message`, and sometimes validation `errors`. Use HTTP status codes (401, 404, 422, etc.) as usual.

---

## 6. Main flows they will need

- **Auth:** Login, register, logout, token refresh (GET /user), password reset (send OTP → validate OTP → update password).
- **Profile:** GET profile, update profile, upload profile image, get profile media.
- **Onboarding:** POST onboarding/save with step data; GET onboarding/get for current profile.
- **Home:** GET /api/home for combined challenges + food logs.
- **Challenges:** List (my + all), create, accept, like, comment, progress/record; categories, limits, start-random.
- **Food logs:** Create, my_food_logs, all_food_logs, like, comment, delete.
- **Chat:** Get rooms (get_contacts / chat/rooms), get messages, send message (room_id + message).
- **Social:** Follow (follow, users/follow, users/:id/follow), friends search.
- **Notifications:** List, unread count, mark one read, mark all read.
- **Subscription:** Get current, get plans, select plan, checkout (stub).

Point them to the exact endpoint names in `API_ENDPOINTS.md` for each flow.

---

## 7. Optional: Postman/Insomnia collection

- If you have a collection (Postman/Insomnia) with base URL and sample requests for login, profile, challenges, etc., share that so they can hit the API without building the app first.

---

## 8. CORS

- Backend should allow the frontend origin (e.g. Flutter web, or your dev URL). If the app runs on a different host/port, ensure CORS is configured in Laravel for that origin.

---

## Summary checklist for you

- [ ] Share **base URL** (and how to change it per environment).
- [ ] Share **API_ENDPOINTS.md** (full endpoint list).
- [ ] Explain **auth:** login/register return `token`; use `Authorization: Bearer <token>` for protected routes; logout via GET /api/logout.
- [ ] Explain **password reset:** send_otp → validate_otp → update_password (and equivalent auth/* paths).
- [ ] Mention **request headers:** `Content-Type: application/json`, `Accept: application/json`, and Bearer token where required.
- [ ] Mention **file uploads:** multipart/form-data and which field names to use (image, media, etc.).
- [ ] (Optional) Share a **Postman/Insomnia** collection.
- [ ] Confirm **CORS** is set for the frontend origin.

After that, the frontend developer can use `API_ENDPOINTS.md` as the single reference for every endpoint and payload.
