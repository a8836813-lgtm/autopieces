# Chat (client <-> mechanic or shop) with XAMPP

The chat goes through the PHP API and MySQL, so two phones can talk to each other.
Everything runs on your PC; no hosting needed.

## 1. XAMPP
1. Start **Apache** and **MySQL** in the XAMPP control panel.
2. Copy the `php` folder of the project to `C:\xampp\htdocs\autopieces\api`
   (the result must be `C:\xampp\htdocs\autopieces\api\chat\send.php`).
3. Open http://localhost/phpmyadmin. If an `autopieces` database exists from before, **drop it**
   (it only held test data), then import `php/database/schema.sql` and after it `php/database/seed.sql`
   (Import tab). The schema now contains every table, including `chat_messages`.
4. Check in the browser: http://localhost/autopieces/api/ping.php

## 2. Run the app
The server address is `PHP_BASE_URL` (placeholder in `lib/config/app_config.dart`).

| Where the app runs | Command |
|---|---|
| Android emulator | `flutter run` (default `http://10.0.2.2/autopieces/api`) |
| Real phone on the same Wi-Fi | `flutter run --dart-define=PHP_BASE_URL=http://<PC-IP>/autopieces/api` |

Find `<PC-IP>` with `ipconfig` (IPv4 address, e.g. 192.168.1.20). Allow Apache in the Windows firewall
(private network) or the phone cannot reach it.

No server? `flutter run --dart-define=BACKEND=mock` runs the whole app on built-in demo data (chat stays in memory on one phone).

## 3. Test with two devices
1. Phone/emulator A: sign in as **client** (client@demo.dz / demo1234), open **Mechanics**, tap **Chat** on
   *Garage El Amel*, send a message and a photo.
2. Phone/emulator B: sign in as **mechanic** (mechanic@demo.dz / demo1234). The chat icon at the top
   right shows a badge. Open it and reply.
3. For the shop: search a part, tap the chat icon on a result of *Pièces Auto Demo*, and answer from a
   device signed in as **shop** (shop@demo.dz / demo1234).

Only the demo mechanic (m1) and the demo shop (s1) can be answered, because those are the accounts you can sign in
with. Messages to other demo mechanics and shops are stored but nobody reads them.

## How it is built
- `chat_messages` stores plain text references: the client's e-mail, `peer_kind` (mechanic or shop) and
  `peer_id` (m1, s1). It does not depend on the `users` table yet, so the chat works before login is
  connected to MySQL.
- The app asks the server every 3 s inside a conversation and every 5 s for the inbox and badge (polling).
  For instant messages use Supabase Realtime later.
- Photos: JPG, PNG or WebP, 5 MB max, saved with a random name in `php/uploads/chat/`; PHP files cannot run there.

## Known limits (prototype)
- No login token yet: the endpoints trust the e-mail sent by the app. Before real use, add the signed token
  (`JWT_SECRET` in `config.php`) and check it in `php/chat/_chat.php`.
- Polling, not push notifications.
- Job progress photos (mechanic Jobs tab) are still local to the phone that took them. To show them on
  another phone they must be uploaded like the chat photos. Placeholder: not done yet.
