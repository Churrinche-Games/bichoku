# Bichoku release checklist (Juan's steps)

The build plans end at a release candidate; these steps need Juan's accounts or approval. The portfolio's `release-game` skill will run them with him. In order:

1. **Blockers:** a dedicated feedback email (put it in `game_info.cfg` `[feedback] email` and in `docs/privacy-policy.md` for `{{FEEDBACK_EMAIL}}`); the GitHub org `churrinche-games`; the Google Play developer account.
2. **Upload key:** create the keystore outside the repo (`keytool -genkeypair …`), keep it and its passwords out of git; enroll in Play App Signing.
3. **Repo:** push to `github.com/churrinche-games/bichoku`; publish `docs/privacy-policy.md` on GitHub Pages; check the About screen's source link and the Feedback screen's issues link open.
4. **Play Console:** create the app (`com.churrinche.bichoku`, free); listing from `docs/store/listing.es-419.md` and `listing.en-US.md`; icon, feature graphic and screenshots from `tools/store.sh` (`build/store/`: `icon-512.png`, `feature-<lang>.png`, `screenshots/<lang>/` — phone 1080×1920 and 1080×2400, tablet 1600×1200, and 1280×720); content rating questionnaire; target audience 13+; Data safety: no data collected or shared; privacy policy URL.
5. **Closed test:** upload the signed AAB to the closed track; invite the standing tester group (≥12 testers opted in for 14 continuous days).
6. **Production:** promote after the 14 days and any fixes from the testers' feedback. Re-check Play's payments policy (no donation links in the Play build).
7. **itch.io:** donation links in `game_info.cfg` `[support] links`; export with `tools/export.sh web` (upload `build/bichoku-web.zip`, "This file will be played in the browser") and `tools/export.sh itch-apk` (`build/itch/bichoku.apk`; needs the Java SDK path, JDK 17, in Godot's Editor Settings); create the page (free, pay what you want); upload with butler.
8. **Make the repo public** if it isn't yet.
