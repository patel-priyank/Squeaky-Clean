const GITHUB_API_URL = 'https://api.github.com/repos/patel-priyank/Squeaky-Clean/releases/latest';
const GITHUB_RELEASES_URL = 'https://github.com/patel-priyank/Squeaky-Clean/releases/latest';

export default async function handler(_req, res) {
  try {
    const response = await fetch(GITHUB_API_URL, {
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'squeaky-clean-website'
      }
    });

    if (!response.ok) {
      throw new Error(`GitHub API returned ${response.status}`);
    }

    const release = await response.json();
    const asset = (release.assets || []).find(a => a.name.toLowerCase().endsWith('.zip'));

    if (!asset) {
      throw new Error('No .zip asset found in the latest release');
    }

    res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=300');
    res.redirect(302, asset.browser_download_url);
  } catch (error) {
    console.error('Download redirect failed:', error);

    res.setHeader('Cache-Control', 'no-store');
    res.redirect(302, GITHUB_RELEASES_URL);
  }
}
