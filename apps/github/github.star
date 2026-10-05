"""
Tidbyt GitHub Repos App
Shows status for key GitHub repositories, cycling between them:
  - CI status of a workflow on a branch (last finished run: PASS / FAIL, plus RUN if one is in progress)
  - Stars, forks, and how many open PRs a given user has in that repo
Config options:
  - repos:        Comma-separated 'owner/repo' list (default: 'block/buzz,block/buzz-app')
  - github_user:  Whose open PRs to count (default: 'wesbillman')
  - workflow:     Workflow name to treat as CI (default: 'CI')
  - branch:       Branch to check CI on (default: 'main')
  - github_token: Optional PAT (private repos, and 5,000 req/hr instead of 60)
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")

# 9x9 pixel GitHub Octocat silhouette
GH_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAANElEQVR4nGNgAIL/QMCABcDF/yMBdAVw8f9EALgiNM0ofOJMQrcfqwJsDsWqAKuP8AFsCgCuT8U7QoYvmAAAAABJRU5ErkJggg=="

# 5x5 pixel metric icons
STAR_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHUlEQVR4nGNggIL/1xn+MyBz0DGGBAO6VhRBdAAAkk0fKM3dXasAAAAASUVORK5CYII="
FORK_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAGUlEQVR4nGNI2frtPwMQoNOYAjCAIUCUIAA8MRhxfZ17BQAAAABJRU5ErkJggg=="

DEFAULT_REPOS = "block/buzz,block/buzz-app"
DEFAULT_USER = "wesbillman"
DEFAULT_WORKFLOW = "CI"
DEFAULT_BRANCH = "main"

FRAME_MS = 4000

GREEN = "#00E676"
RED = "#FF5252"
YELLOW = "#FFD600"
GRAY = "#9E9E9E"
STAR_COLOR = "#FFD700"
FORK_COLOR = "#64B5F6"
PR_COLOR = "#B388FF"

FAIL_CONCLUSIONS = ["failure", "timed_out", "startup_failure"]
IGNORED_CONCLUSIONS = ["cancelled", "skipped", "neutral", "stale"]

def format_count(n):
    # JSON numbers arrive as floats; show ints, abbreviating >= 1000 (e.g. 2.4k)
    n = int(n)
    if n >= 1000:
        whole = n // 1000
        tenth = (n % 1000) // 100
        if whole >= 10 or tenth == 0:
            return "%dk" % whole
        return "%d.%dk" % (whole, tenth)
    return str(n)

def gh_get(url, headers, ttl):
    return http.get(url, ttl_seconds = ttl, headers = headers)

def fetch_my_prs(repo_list, user, headers):
    # One search call for all repos -> {"owner/repo": count}
    counts = {}
    if not user:
        return counts
    q = "is:pr+is:open+author:%s" % user
    for r in repo_list:
        q += "+repo:" + r
    res = gh_get("https://api.github.com/search/issues?per_page=100&q=" + q, headers, 300)
    if res.status_code != 200:
        return None
    for item in res.json().get("items", []):
        # repository_url: https://api.github.com/repos/owner/repo
        name = "/".join(item.get("repository_url", "").split("/")[-2:]).lower()
        counts[name] = counts.get(name, 0) + 1
    return counts

def fetch_ci(repo_full_name, workflow, branch, headers):
    # Returns (label, color, running)
    url = "https://api.github.com/repos/%s/actions/runs?per_page=30&branch=%s" % (repo_full_name, branch)
    res = gh_get(url, headers, 180)
    if res.status_code != 200:
        return "CI ?", GRAY, False

    runs = [
        r
        for r in res.json().get("workflow_runs", [])
        if (r.get("name") or "").lower() == workflow.lower()
    ]
    if not runs:
        return "NO CI", GRAY, False

    running = runs[0].get("status") != "completed"

    for r in runs:
        if r.get("status") != "completed":
            continue
        conclusion = r.get("conclusion") or ""
        if conclusion in IGNORED_CONCLUSIONS:
            continue
        if conclusion == "success":
            return "CI PASS", GREEN, running
        if conclusion in FAIL_CONCLUSIONS:
            return "CI FAIL", RED, running
        return "CI " + conclusion[:4].upper(), YELLOW, running

    # Nothing finished yet in the recent window
    return ("CI RUN", YELLOW, False) if running else ("CI ?", GRAY, False)

def message_frame(text, color):
    return render.Box(
        width = 64,
        height = 32,
        child = render.Text(text, color = color, font = "tom-thumb"),
    )

def metric(icon_b64, label, value, color):
    children = []
    if icon_b64:
        children.append(render.Image(src = base64.decode(icon_b64)))
        children.append(render.Box(width = 1, height = 1))
    if label:
        children.append(render.Text(label, color = color, font = "tom-thumb"))
        children.append(render.Box(width = 2, height = 1))
    children.append(render.Text(value, color = color, font = "tom-thumb"))
    return render.Row(cross_align = "center", children = children)

def render_repo_frame(repo_full_name, headers, workflow, branch, my_prs):
    parts = repo_full_name.split("/")
    if len(parts) != 2:
        return message_frame("Bad repo name", RED)
    repo = parts[1]

    res = gh_get("https://api.github.com/repos/" + repo_full_name, headers, 600)
    if res.status_code == 404:
        return message_frame("%s 404" % repo[:10], RED)
    if res.status_code == 403:
        return message_frame("Rate limited", YELLOW)
    if res.status_code != 200:
        return message_frame("Err %d" % res.status_code, RED)

    data = res.json()
    stars = format_count(data.get("stargazers_count", 0))
    forks = format_count(data.get("forks_count", 0))

    ci_label, ci_color, ci_running = fetch_ci(repo_full_name, workflow, branch, headers)

    if my_prs == None:
        pr_value = "?"
    else:
        pr_value = str(my_prs.get(repo_full_name.lower(), 0))

    ci_row = [
        render.Box(width = 3, height = 3, color = ci_color),
        render.Box(width = 2, height = 1),
        render.Text(ci_label, color = ci_color, font = "tom-thumb"),
    ]
    if ci_running and ci_label != "CI RUN":
        ci_row.append(render.Box(width = 3, height = 1))
        ci_row.append(render.Text("RUN", color = YELLOW, font = "tom-thumb"))

    return render.Box(
        width = 64,
        height = 32,
        padding = 1,
        child = render.Column(
            expanded = True,
            cross_align = "start",
            main_align = "space_between",
            children = [
                # Row 1: Icon + Repo name
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = base64.decode(GH_ICON)),
                        render.Box(width = 2, height = 1),
                        render.Marquee(
                            width = 51,
                            child = render.Text(repo, color = "#FFFFFF", font = "CG-pixel-4x5-mono"),
                        ),
                    ],
                ),
                # Row 2: CI status on branch
                render.Row(cross_align = "center", children = ci_row),
                # Row 3: Stars, forks, my open PRs
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        metric(STAR_ICON, "", stars, STAR_COLOR),
                        metric(FORK_ICON, "", forks, FORK_COLOR),
                        metric(None, "PR", pr_value, PR_COLOR),
                    ],
                ),
            ],
        ),
    )

def main(config):
    repos_str = config.get("repos") or DEFAULT_REPOS
    user = config.get("github_user") or DEFAULT_USER
    workflow = config.get("workflow") or DEFAULT_WORKFLOW
    branch = config.get("branch") or DEFAULT_BRANCH
    token = config.get("github_token", "")

    headers = {
        "User-Agent": "Tidbyt-GitHub-App",
        "Accept": "application/vnd.github+json",
    }
    if token:
        headers["Authorization"] = "Bearer " + token

    repo_list = [r.strip() for r in repos_str.split(",") if r.strip()]
    if not repo_list:
        return render.Root(child = message_frame("No repos configured", RED))

    my_prs = fetch_my_prs(repo_list, user, headers)
    frames = [render_repo_frame(r, headers, workflow, branch, my_prs) for r in repo_list]

    if len(frames) == 1:
        return render.Root(child = frames[0])

    return render.Root(
        delay = FRAME_MS,
        child = render.Animation(children = frames),
    )
