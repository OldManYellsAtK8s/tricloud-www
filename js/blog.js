// Config — set these 3 values once your blog repo is ready.
// GITHUB_OWNER can be a user or an organisation name — the API path is the same either way.
// Expected repo structure: posts/YYYY-MM-DD-slug.md (frontmatter + markdown body)
const GITHUB_OWNER = 'TriCloud-Tech';
const GITHUB_REPO  = 'tricloud-www-blog';
const BRANCH       = 'main';
const POSTS_DIR    = 'posts';

const RAW_BASE = `https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${BRANCH}/${POSTS_DIR}`;
const API_URL  = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${POSTS_DIR}?ref=${BRANCH}`;

// Directory listing via API (1 authenticated-free call), file content via raw CDN (no rate limit).
async function fetchPostList() {
  const res = await fetch(API_URL);
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
  const files = await res.json();
  return files
    .filter(f => f.type === 'file' && f.name.endsWith('.md'))
    .sort((a, b) => b.name.localeCompare(a.name)); // newest first — relies on YYYY-MM-DD prefix
}

async function fetchPostContent(filename) {
  const res = await fetch(`${RAW_BASE}/${encodeURIComponent(filename)}`);
  if (!res.ok) throw new Error(`${res.status}`);
  return res.text();
}

// Minimal YAML frontmatter parser (key: value lines between --- delimiters).
function parseFrontmatter(raw) {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) return { meta: {}, body: raw };
  const meta = {};
  for (const line of match[1].split(/\r?\n/)) {
    const idx = line.indexOf(':');
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    const val  = line.slice(idx + 1).trim().replace(/^["']|["']$/g, '');
    if (key) meta[key] = val;
  }
  return { meta, body: match[2].trim() };
}

function formatDate(str) {
  const d = new Date(str);
  return isNaN(d) ? str : d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
}

function postCard({ meta, filename }) {
  const img     = meta.image   ? `<img src="${meta.image}" alt="" class="blog-thumb" />` : '';
  const excerpt = meta.excerpt ? `<p class="blog-excerpt">${meta.excerpt}</p>` : '';
  const date    = meta.date    ? `<span class="blog-date">${formatDate(meta.date)}</span>` : '';
  return `
    <a class="blog-card panel" href="post.html?file=${encodeURIComponent(filename)}">
      ${img}
      <div class="blog-card-body">
        ${date}
        <h3 class="blog-title">${meta.title || filename}</h3>
        ${excerpt}
        <span class="blog-read-more">Read post <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></span>
      </div>
    </a>`;
}

function featuredCard({ meta, filename }) {
  const img     = meta.image   ? `<div class="featured-img-wrap"><img src="${meta.image}" alt="" class="featured-img" /></div>` : '';
  const excerpt = meta.excerpt ? `<p class="blog-excerpt" style="-webkit-line-clamp:4;line-clamp:4;">${meta.excerpt}</p>` : '';
  const date    = meta.date    ? `<span class="blog-date">${formatDate(meta.date)}</span>` : '';
  return `
    <a class="featured-card panel" href="post.html?file=${encodeURIComponent(filename)}">
      ${img}
      <div class="blog-card-body">
        ${date}
        <h3 class="blog-title" style="font-size:1.3rem;line-height:1.25;">${meta.title || filename}</h3>
        ${excerpt}
        <span class="blog-read-more">Read post <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></span>
      </div>
    </a>`;
}

function renderError(container) {
  container.innerHTML = `<p style="color:var(--muted);">Could not load posts — check back soon.</p>`;
}

window.Blog = {
  fetchPostList, fetchPostContent, parseFrontmatter,
  formatDate, postCard, featuredCard, renderError,
  RAW_BASE, GITHUB_OWNER, GITHUB_REPO, BRANCH, POSTS_DIR
};
