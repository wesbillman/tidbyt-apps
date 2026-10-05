"""
Tidbyt GitHub Key Repos App
Displays status for one or more key GitHub repositories.
Cycles through repos with an animation if multiple are specified.
Config options:
  - repos: Comma-separated list of 'owner/repo' (default: 'wesbillman/vibes_ui,tidbyt/pixlet')
  - github_token: Optional GitHub Personal Access Token (for private repos & 5,000 req/hr rate limit)
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")

# 9x9 pixel GitHub Octocat silhouette
GH_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAANElEQVR4nGNgAIL/QMCABcDF/0MBLkVguf9EABSTsNHEm4SsA6cCdJ+g01h9gtMUbAqRxQG5f79BLSyF1gAAAABJRU5ErkJggg=="

DEFAULT_REPOS = "wesbillman/vibes_ui,tidbyt/pixlet"

def render_repo_frame(repo_full_name, headers):
    parts = repo_full_name.strip().split("/")
    if len(parts) != 2:
        return render.Box(
            child = render.Text("Bad repo name", color = "#ff4444", font = "CG-pixel-3x5-mono"),
        )
    owner = parts[0]
    repo = parts[1]

    # 1. Fetch Repo info
    repo_url = "https://api.github.com/repos/%s/%s" % (owner, repo)
    res = http.get(repo_url, ttl_seconds = 120, headers = headers)

    if res.status_code == 404:
        return render.Box(
            child = render.Text("%s 404" % repo[:8], color = "#ff4444", font = "CG-pixel-3x5-mono"),
        )
    if res.status_code == 403:
        return render.Box(
            child = render.Text("Rate limited", color = "#ffaa00", font = "CG-pixel-3x5-mono"),
        )
    if res.status_code != 200:
        return render.Box(
            child = render.Text("Err %d" % res.status_code, color = "#ff4444", font = "CG-pixel-3x5-mono"),
        )

    data = res.json()
    stars = data.get("stargazers_count", 0)
    forks = data.get("forks_count", 0)
    issues = data.get("open_issues_count", 0)
    lang = data.get("language") or "Code"

    # 2. Fetch Latest CI run
    ci_url = "https://api.github.com/repos/%s/%s/actions/runs?per_page=1" % (owner, repo)
    ci_res = http.get(ci_url, ttl_seconds = 120, headers = headers)

    ci_status = ""
    ci_color = "#888888"
    if ci_res.status_code == 200:
        runs = ci_res.json().get("workflow_runs", [])
        if runs:
            latest = runs[0]
            conclusion = latest.get("conclusion")
            status = latest.get("status")
            if status == "in_progress":
                ci_status = "CI: RUN"
                ci_color = "#FFD600"
            elif conclusion == "success":
                ci_status = "CI: PASS"
                ci_color = "#00E676"
            elif conclusion == "failure":
                ci_status = "CI: FAIL"
                ci_color = "#FF5252"
            elif conclusion:
                ci_status = "CI: " + conclusion[:4].upper()
                ci_color = "#FFAA00"

    # If no CI status, show the primary language
    if not ci_status:
        ci_status = lang[:9]
        ci_color = "#9E9E9E"

    return render.Box(
        padding = 1,
        child = render.Column(
            cross_align = "start",
            main_align = "space_between",
            children = [
                # Row 1: Icon + Repo Name (Marquee for long names)
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

                # Row 2: Status / CI badge
                render.Row(
                    expanded = True,
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Box(width = 3, height = 3, color = ci_color),
                        render.Box(width = 2, height = 1),
                        render.Text(ci_status, color = ci_color, font = "CG-pixel-3x5-mono"),
                    ],
                ),

                # Row 3: Metrics (Stars, Forks, Issues)
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Text("*", color = "#FFD700", font = "CG-pixel-3x5-mono"),
                                render.Text(str(stars), color = "#FFD700", font = "CG-pixel-3x5-mono"),
                            ],
                        ),
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Text("Y", color = "#64B5F6", font = "CG-pixel-3x5-mono"),
                                render.Text(str(forks), color = "#64B5F6", font = "CG-pixel-3x5-mono"),
                            ],
                        ),
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Text("!", color = "#FF8A80", font = "CG-pixel-3x5-mono"),
                                render.Text(str(issues), color = "#FF8A80", font = "CG-pixel-3x5-mono"),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main(config):
    repos_str = config.get("repos", DEFAULT_REPOS)
    token = config.get("github_token", "")

    headers = {
        "User-Agent": "Tidbyt-GitHub-App",
        "Accept": "application/vnd.github.v3+json",
    }
    if token:
        headers["Authorization"] = "Bearer " + token

    repo_list = [r.strip() for r in repos_str.split(",") if r.strip()]
    if not repo_list:
        return render.Root(
            child = render.Box(child = render.Text("No repos configured", color = "#FF5252", font = "CG-pixel-3x5-mono")),
        )

    # If only 1 repo, return a static screen
    if len(repo_list) == 1:
        return render.Root(
            child = render_repo_frame(repo_list[0], headers),
        )

    # For multiple repos, cycle with animation frames (3.5 seconds each)
    frames = []
    for r in repo_list:
        frames.append(render_repo_frame(r, headers))

    return render.Root(
        delay = 3500,
        child = render.Animation(
            children = frames,
        ),
    )
