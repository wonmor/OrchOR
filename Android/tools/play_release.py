#!/usr/bin/env python3
"""Google Play release for Orch-OR Visualizer (com.johnseong.orchor).

The app must first exist in Play Console (created by hand) and the service account must have access.

    python3 tools/play_release.py check        # can the service account see the app?
    python3 tools/play_release.py listing      # en-GB texts, icon, feature graphic, screenshots
    python3 tools/play_release.py internal     # upload the AAB to the internal track
    python3 tools/play_release.py production   # promote that versionCode to production

Key: PLAY_SA_JSON (default ~/Documents/keys/havit-play.json). Listing assets come from PLAY_DIR
(default ~/Documents/sr-video/screens/orchor/play). Never prints keys.
"""
import base64, glob, json, os, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request

PKG = "com.johnseong.orchor"
LANG = "en-GB"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAY = os.path.expanduser(os.environ.get("PLAY_DIR", "~/Documents/sr-video/screens/orchor/play"))
# The signed AAB is kept beside the listing (build outputs get cleaned); fall back to the Gradle output.
AAB = next((p for p in (os.environ.get("AAB"), os.path.join(PLAY, "orchor-1.1-release.aab"),
                        os.path.join(ROOT, "app", "build", "outputs", "bundle", "release", "app-release.aab"))
            if p and os.path.exists(p)), os.path.join(PLAY, "orchor-1.1-release.aab"))
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" + PKG
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/" + PKG
NOTES = ("First Android release. Watch tubulin superposition grow across a 3D microtubule and collapse "
         "under the Penrose–Hameroff theory, with a live timeline, a Diósi–Penrose calculator and both "
         "sides of the debate.")


def token():
    k = json.load(open(os.path.expanduser(os.environ.get("PLAY_SA_JSON", "~/Documents/keys/havit-play.json"))))
    b64 = lambda b: base64.urlsafe_b64encode(b).rstrip(b"=")
    now = int(time.time())
    h = b64(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    c = b64(json.dumps({"iss": k["client_email"], "scope": "https://www.googleapis.com/auth/androidpublisher",
                        "aud": k["token_uri"], "iat": now, "exp": now + 3600}).encode())
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        f.write(k["private_key"])
        pk = f.name
    try:
        sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", pk], input=h + b"." + c, capture_output=True).stdout
    finally:
        os.remove(pk)
    body = urllib.parse.urlencode({"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                                   "assertion": (h + b"." + c + b"." + b64(sig)).decode()}).encode()
    return json.load(urllib.request.urlopen(k["token_uri"], body))["access_token"]


TOK = None


def call(url, method="GET", data=None, raw=None, ctype="application/json"):
    global TOK
    TOK = TOK or token()
    body = raw if raw is not None else (json.dumps(data).encode() if data is not None else None)
    req = urllib.request.Request(url, data=body, method=method,
                                 headers={"Authorization": "Bearer " + TOK, "Content-Type": ctype})
    try:
        r = urllib.request.urlopen(req, timeout=900).read()
        return json.loads(r) if r else {}
    except urllib.error.HTTPError as e:
        return {"err": e.code, "body": e.read().decode()[:800]}


def edit():
    e = call(API + "/edits", "POST", {})
    if "id" not in e:
        sys.exit(f"cannot open an edit for {PKG}: {e}")
    return e["id"]


def commit(eid):
    print("commit", call(API + f"/edits/{eid}:commit", "POST", {}))


def text(name):
    return open(os.path.join(PLAY, name)).read().strip()


def listing():
    eid = edit()
    for t in (NOTES, text("short-description.txt"), text("full-description.txt")):
        assert "·" not in t and "•" not in t
    print("details", call(API + f"/edits/{eid}/details", "PATCH", {"defaultLanguage": LANG, "contactEmail": "wonmor@yahoo.com"}))
    print("listing", call(API + f"/edits/{eid}/listings/{LANG}", "PUT", {
        "language": LANG, "title": text("title.txt"),
        "shortDescription": text("short-description.txt"), "fullDescription": text("full-description.txt")}).get("title"))
    imgs = {"icon": ["play-icon-512.png"], "featureGraphic": ["feature-graphic-1024x500.png"],
            "phoneScreenshots": sorted(glob.glob(os.path.join(PLAY, "screenshots", "phone", "*.png"))),
            "sevenInchScreenshots": sorted(glob.glob(os.path.join(PLAY, "screenshots", "tablet7", "*.png"))),
            "tenInchScreenshots": sorted(glob.glob(os.path.join(PLAY, "screenshots", "tablet10", "*.png")))}
    for kind, files in imgs.items():
        call(API + f"/edits/{eid}/listings/{LANG}/{kind}", "DELETE")
        for f in files:
            r = call(UPLOAD + f"/edits/{eid}/listings/{LANG}/{kind}?uploadType=media", "POST",
                     raw=open(os.path.join(PLAY, f), "rb").read(), ctype="image/png")
            print(kind, os.path.basename(f), "ok" if "image" in r else r)
    commit(eid)


def internal():
    if not os.path.exists(AAB):
        sys.exit("Build the signed AAB first: ./gradlew :app:bundleRelease")
    eid = edit()
    up = call(UPLOAD + f"/edits/{eid}/bundles?uploadType=media", "POST", raw=open(AAB, "rb").read(),
              ctype="application/octet-stream")
    if "versionCode" not in up:
        sys.exit(f"upload failed: {up}")
    vc = up["versionCode"]
    print("uploaded versionCode", vc)
    print("track", call(API + f"/edits/{eid}/tracks/internal", "PUT", {"track": "internal", "releases": [
        {"name": f"1.1 ({vc})", "versionCodes": [str(vc)], "status": "completed",
         "releaseNotes": [{"language": LANG, "text": NOTES}]}]}).get("track"))
    commit(eid)


def production():
    eid = edit()
    rel = call(API + f"/edits/{eid}/tracks/internal")
    vcs = rel["releases"][0]["versionCodes"]
    print("track", call(API + f"/edits/{eid}/tracks/production", "PUT", {"track": "production", "releases": [
        {"name": f"1.1 ({vcs[0]})", "versionCodes": vcs, "status": "completed",
         "releaseNotes": [{"language": LANG, "text": NOTES}]}]}))
    commit(eid)


def check():
    e = call(API + "/edits", "POST", {})
    if "id" in e:
        print("OK: service account can edit", PKG)
        call(API + f"/edits/{e['id']}", "DELETE")
    else:
        print("NO ACCESS:", e)


if __name__ == "__main__":
    {"check": check, "listing": listing, "internal": internal, "production": production}[sys.argv[1] if len(sys.argv) > 1 else "check"]()
