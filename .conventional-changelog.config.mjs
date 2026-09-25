import createPreset from "conventional-changelog-conventionalcommits";

const REPO_URL = "https://github.com/dont-be-evil-company/kulala.nvim";

export default createPreset({
  formatCommitUrl: (_context, commit) =>
    `${REPO_URL}/commit/${commit.hash}`,
  formatCompareUrl: (context) =>
    `${REPO_URL}/compare/${context.previousTag}...${context.currentTag}`,
  ignoreCommits: /^skip-changelog\b/i,
});
