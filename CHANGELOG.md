## [6.29.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.28.0...v6.29.0) (2026-09-25)

### Features

* **openapi:** fix explorer nav and add file picker ([232a993](https://github.com/dont-be-evil-company/kulala.nvim/commit/232a9939919fe9bc88d573bce92de50f2f160c60))

### Bug Fixes

* bug +n panel open (strip title for new lines) ([dcad056](https://github.com/dont-be-evil-company/kulala.nvim/commit/dcad056448773ae5b54cadbfdbd188a599cfebd3))

## [6.28.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.27.0...v6.28.0) (2026-08-12)

### Features

* **grpc:** add support `@grpc-insecure` operator ([b1c1cd9](https://github.com/dont-be-evil-company/kulala.nvim/commit/b1c1cd9430d1f506e9b7add09cc2f2aac067565f))

## [6.27.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.26.1...v6.27.0) (2026-08-11)

### Features

* **image:** add image support to the response view ([81cbb76](https://github.com/dont-be-evil-company/kulala.nvim/commit/81cbb767749bfe23666e8ff099306044a2743012))

## [6.26.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.26.0...v6.26.1) (2026-08-11)

### Bug Fixes

* **docs:** update docs (openapi, keymaps, scripts) ([d9ccbeb](https://github.com/dont-be-evil-company/kulala.nvim/commit/d9ccbebd3db677a4255b24d997bcd8c2a65dedb7))
* **tests:** fix script console notify spec ([0f3fbf7](https://github.com/dont-be-evil-company/kulala.nvim/commit/0f3fbf7664862a575bb39045138785b5db84b82a))

## [6.26.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.25.0...v6.26.0) (2026-08-11)

### ⚠ BREAKING CHANGES

* **openapi:** `@kulala-openapi-json` is now `@kulala-openapi-explorer`.

### break

* **openapi:** extend script support and shared headers ([4f24ced](https://github.com/dont-be-evil-company/kulala.nvim/commit/4f24ced4df6d2f816e52fa241cfa1fbdc384a370))

### Features

* **openapi:** add openapi explorer support ([69d27b9](https://github.com/dont-be-evil-company/kulala.nvim/commit/69d27b98f145c29d743b71d48fdbe4b8b98000a0))
* **scripts:** add $kulala.request.abort() ([e6b9c72](https://github.com/dont-be-evil-company/kulala.nvim/commit/e6b9c72fa1b027ec123aa635d7ffc0f613b6afc7))

## [6.23.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.23.1...v6.23.2) (2026-08-04)

### Bug Fixes

* **scripts:** allow require/import in scripts ([7c10bd7](https://github.com/dont-be-evil-company/kulala.nvim/commit/7c10bd7b56f11dca25e5e948f817ca4eee1cb669))

## [6.23.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.23.0...v6.23.1) (2026-08-04)

### Features

* **websockets:** enable in/out support ([e4e8615](https://github.com/dont-be-evil-company/kulala.nvim/commit/e4e8615dc07d9423f3dd52ad5af962db09d26a52))

### Bug Fixes

* **backend:** try resolve binary path from config first ([58233e1](https://github.com/dont-be-evil-company/kulala.nvim/commit/58233e176c0f020ffb796cbadc73ad9d5f1e7486))

## [6.22.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.21.2...v6.22.0) (2026-07-24)

### Bug Fixes

* **docs:** change emoji in README.md ([a9e17ae](https://github.com/dont-be-evil-company/kulala.nvim/commit/a9e17ae0236e886371671a7a9f01f070201a9cc1))
* **env_manager:** fix env_manager cache showing stale info ([9c03fdb](https://github.com/dont-be-evil-company/kulala.nvim/commit/9c03fdb84c8df3df8d410e8f974b4061e19c3292))
* **graphql:** context with preambles ([74e35fa](https://github.com/dont-be-evil-company/kulala.nvim/commit/74e35fa31b86c39cf9c8e9000ab0321ccac1011b))
* **lsp:** client-reference in docs ([6c0ef6e](https://github.com/dont-be-evil-company/kulala.nvim/commit/6c0ef6e6b00a0c4c384579345197ad11f59c03e4))
* **scripts:** update deps and fix changelog generation ([207922b](https://github.com/dont-be-evil-company/kulala.nvim/commit/207922b12a7fe198a81ece11608b91a68503f76f))
* **show_help:** ignore keymaps set to false ([91cf892](https://github.com/dont-be-evil-company/kulala.nvim/commit/91cf892008c773ce74ac392c4c12ddff775b7619))
* **ui:** body-view, comments in http files ([5c2234e](https://github.com/dont-be-evil-company/kulala.nvim/commit/5c2234e1a0ae8a95911231682c52be2a13fcc117))

## [6.21.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.7...v6.21.0) (2026-07-07)

### Features

* **treesitter:** update treesitter to support kulala-jq syntax ([84cb164](https://github.com/dont-be-evil-company/kulala.nvim/commit/84cb164d2088e2c781bedde0229610ff0d7f0eec))

## [6.20.7](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.6...v6.20.7) (2026-07-03)

### Bug Fixes

* file corruption during binary uploads ([5a2883c](https://github.com/dont-be-evil-company/kulala.nvim/commit/5a2883ce52bc5feb6eb1f0ddd19de06bb4033144))

## [6.20.6](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.5...v6.20.6) (2026-07-03)

### Bug Fixes

* **core:** fix timeout ([46fcb73](https://github.com/dont-be-evil-company/kulala.nvim/commit/46fcb73f87f6bfdb1725c23d688b1afff51a8162))

## [6.20.5](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.4...v6.20.5) (2026-07-01)

### Bug Fixes

* **curl:** omit content-type header if not set by user ([7fba542](https://github.com/dont-be-evil-company/kulala.nvim/commit/7fba542e4300c0d915f64da8a759f68ca1bd6b77))

## [6.20.4](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.3...v6.20.4) (2026-06-30)

### Bug Fixes

* **lsp:** replace too greedy ([f3804a9](https://github.com/dont-be-evil-company/kulala.nvim/commit/f3804a9a581fe9a63ef42fbe00d58fb7589169f9))

## [6.20.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.2...v6.20.3) (2026-06-30)

### Bug Fixes

* **lsp, requests:** lsp completions & requests w/o content-type and data ([f3934f2](https://github.com/dont-be-evil-company/kulala.nvim/commit/f3934f22387cb62e62ff4ced16c42b66f7906a15))

## [6.20.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.1...v6.20.2) (2026-06-29)

### Bug Fixes

* **grpc, lsp, stdout:** grpc tls+verbose, lsp filter by name, await stdout ([b44a184](https://github.com/dont-be-evil-company/kulala.nvim/commit/b44a184f222ad5c76ceb37bff4af14ab45f29c05))

## [6.20.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.20.0...v6.20.1) (2026-06-27)

### Bug Fixes

* **lsp:** remove inlay_hints config option and let user handle this ([b78b1aa](https://github.com/dont-be-evil-company/kulala.nvim/commit/b78b1aab31844bdba8a94041ff22a61d1563ba35))

## [6.20.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.19.1...v6.20.0) (2026-06-27)

### Features

* **lsp, runner:** add lsp inlay_hints + auto encode urls ([4358d20](https://github.com/dont-be-evil-company/kulala.nvim/commit/4358d201df794ab72898bbee192baaa9c8f89495))

## [6.19.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.19.0...v6.19.1) (2026-06-27)

### Bug Fixes

* **lsp:** fix lsp textEdit adding extra characters ([8febe18](https://github.com/dont-be-evil-company/kulala.nvim/commit/8febe189df1e66e2d045cff76b74a9db83157c73))
* **variables:** request-vars not resolved via jsonPath ([a050ff5](https://github.com/dont-be-evil-company/kulala.nvim/commit/a050ff59df11bf771c4edfe64fbb20d5a21e24f1))

## [6.19.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.18.0...v6.19.0) (2026-06-27)

### Features

* **backend:** make download_tool configurable ([0b09e6b](https://github.com/dont-be-evil-company/kulala.nvim/commit/0b09e6b66d11908e0c00b98b39e40dcbef836489))

## [6.18.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.17.1...v6.18.0) (2026-06-27)

### Features

* **treesitter:** enable opt-out of treesitter management ([5ec1bd4](https://github.com/dont-be-evil-company/kulala.nvim/commit/5ec1bd462c7ac3a72a81207d8eb0b1458ea18410))

## [6.17.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.17.0...v6.17.1) (2026-06-27)

### Bug Fixes

* **oauth:** browser-flow on windows ([f116cc3](https://github.com/dont-be-evil-company/kulala.nvim/commit/f116cc3391b62276176a356c8d56308d89a68e55))

## [6.17.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.16.2...v6.17.0) (2026-06-26)

### Features

* **scripting:** add $kulala.runRequest similar to bruno scripting works ([8848e90](https://github.com/dont-be-evil-company/kulala.nvim/commit/8848e90bf05b8416e02b2561039b70acc271071c))

## [6.16.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.16.1...v6.16.2) (2026-06-25)

### Bug Fixes

* **lsp, oauth:** lsp triggering oauth flow on hover ([87c8f01](https://github.com/dont-be-evil-company/kulala.nvim/commit/87c8f0136f0eaebe1dcea6f7448a34cea40b9513))

## [6.16.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.16.0...v6.16.1) (2026-06-24)

### Bug Fixes

* **oauth2:** read client secret from private file ([77df991](https://github.com/dont-be-evil-company/kulala.nvim/commit/77df991c79a52230ac14b1613756179be9ec2fc8))

## [6.16.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.15.3...v6.16.0) (2026-06-22)

### Features

* allow passing function to split_direction ([46b9ae8](https://github.com/dont-be-evil-company/kulala.nvim/commit/46b9ae869c10b676f083ab023a6f168b762974ae))

### Bug Fixes

* **backend:** update backend to fix crlf parser crash ([a627ebc](https://github.com/dont-be-evil-company/kulala.nvim/commit/a627ebcafe2d053fa395b2d324dc9f6cbb61495e))

## [6.15.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.15.2...v6.15.3) (2026-06-19)

### Bug Fixes

* **backend:** backend parser stripped compat mode when importing files ([bed6150](https://github.com/dont-be-evil-company/kulala.nvim/commit/bed6150762d4a5ab5c0a336ebb01626f7ad0ab26))

## [6.15.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.15.1...v6.15.2) (2026-06-19)

### Bug Fixes

* **operator:** prompt not always triggered when running all requests ([26ad237](https://github.com/dont-be-evil-company/kulala.nvim/commit/26ad237872ecc52d6ea20311f1c47cbeb090f129))

## [6.15.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.15.0...v6.15.1) (2026-06-19)

### Bug Fixes

* **operators:** kulala-prompt operator didn't respect type ([b4105ef](https://github.com/dont-be-evil-company/kulala.nvim/commit/b4105ef86382d879554f20865c81419280dc0fa4))

## [6.15.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.14.0...v6.15.0) (2026-06-18)

### Bug Fixes

* **lint:** test stubs ([143966c](https://github.com/dont-be-evil-company/kulala.nvim/commit/143966c65767414f8b3d545d44b86902ab0f0843))
* **websocket, lsp:** variable substitution and lsp hover ([3dc1b52](https://github.com/dont-be-evil-company/kulala.nvim/commit/3dc1b52d89183650936a8d48fcc0cf7d279f5a9e))

## [6.14.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.12.0...v6.14.0) (2026-06-16)

### Features

* support luarocks/rocks.nvim ([ee1437a](https://github.com/dont-be-evil-company/kulala.nvim/commit/ee1437ad85a4750f91b3ffdbcb07d3f94203d647))

### Bug Fixes

* **ci:** add missing .node-version ([b7e13ea](https://github.com/dont-be-evil-company/kulala.nvim/commit/b7e13ead3de3f8ae4fc3d674ed23e3802871de2a))
* **ci:** pnpm version and add mise config ([f83b3e5](https://github.com/dont-be-evil-company/kulala.nvim/commit/f83b3e55d3505234858ece5bcd13db119f1d94db))
* **parser:** don't install if managed externally ([6961d38](https://github.com/dont-be-evil-company/kulala.nvim/commit/6961d38902467cb293d5d80438efda9a12eec037))
* **test:** stubs for grpcurl and websocat & bump versions ([a2578df](https://github.com/dont-be-evil-company/kulala.nvim/commit/a2578df20a0fa0090b3e284336582ae9f9779e03))

## [6.12.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.11.1...v6.12.0) (2026-06-16)

### Features

* **grpc:** add reflection support ([9945d57](https://github.com/dont-be-evil-company/kulala.nvim/commit/9945d576751c8a6a8331c46fc9436d62e796ff28))

### Bug Fixes

* **docs:** badge ([bf50254](https://github.com/dont-be-evil-company/kulala.nvim/commit/bf50254965aff8228fa51067d79bb16d2124461e))

## [6.11.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.11.0...v6.11.1) (2026-06-13)

### Features

* **sessions:** add session restore ([584716f](https://github.com/dont-be-evil-company/kulala.nvim/commit/584716fd13b8ebd1987284e08a08f3b357e88dc9))

### Bug Fixes

* **minit:** fix scripts for mac and linux ([b069eb9](https://github.com/dont-be-evil-company/kulala.nvim/commit/b069eb9cad3e19f2d477ba7e8a8e3c2cf543ea88))
* **ui:** ctrl+c error in queue method ([5421040](https://github.com/dont-be-evil-company/kulala.nvim/commit/54210402761995d15c7492863a3dcf5b885ba34e))

## [6.11.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.10.1...v6.11.0) (2026-06-12)

### Features

* **ui, jq, lsp:** refactor websockets, add jq filter, fix lsp restart ([6b178fc](https://github.com/dont-be-evil-company/kulala.nvim/commit/6b178fc1bf46d343a6d0244953619c71da97ef97))

### Bug Fixes

* **version:** downgrade plugin version to 6.11.0 ([ab976c8](https://github.com/dont-be-evil-company/kulala.nvim/commit/ab976c8d799b93ca7de1a0f38f8df711aff8d84d))

## [6.10.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.10.0...v6.10.1) (2026-06-12)

### Features

* **tree-sitter:** notify user and refactor ([5f81cb6](https://github.com/dont-be-evil-company/kulala.nvim/commit/5f81cb6e6977dcad7fa2c2f3e6f5d3a32473c1e9))

### Bug Fixes

* **tree-sitter:** fetch grammar on demand instead of a submodule ([12b6242](https://github.com/dont-be-evil-company/kulala.nvim/commit/12b6242d398104bb2673023837bb6e213b5c22cd))
* **ui:** remove news footer ([6bf3e2d](https://github.com/dont-be-evil-company/kulala.nvim/commit/6bf3e2d6d7ed5864c0f8ee7982a5c3263c018acd))
* **ui:** remove unused import ([0d5be25](https://github.com/dont-be-evil-company/kulala.nvim/commit/0d5be25d343891741a54dd94e36e6bdc65e7eee9))

## [6.10.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.9.2...v6.10.0) (2026-06-11)

### Features

* **tree-sitter, cli:** remove cli and use upstream tree-sitter repo ([ba4df2d](https://github.com/dont-be-evil-company/kulala.nvim/commit/ba4df2dc0b6d4a4f8bba0a039e64adae32d3ecad))
* **ui, fmt:** remove fmt and enable response pretty-print ([fdb9ad2](https://github.com/dont-be-evil-company/kulala.nvim/commit/fdb9ad21fc1621c5f98f766c84601d9b3f1e971f))
* **ui:** pretty-print xml ([5f37d5c](https://github.com/dont-be-evil-company/kulala.nvim/commit/5f37d5cbcf55f9f1c6d38299d9c6b4b669cf7d86))

### Bug Fixes

* **ci:** git submodule update --init --recursive ([a6f38ca](https://github.com/dont-be-evil-company/kulala.nvim/commit/a6f38ca546ddc22161c89f91c10db4478fd11d19))
* **ci:** remove lint docs ([c1326b3](https://github.com/dont-be-evil-company/kulala.nvim/commit/c1326b349d72a6d94ff40f304886960719d70e8e))
* **fmt:** remove module ([734cfd1](https://github.com/dont-be-evil-company/kulala.nvim/commit/734cfd1c60758353a3436888640ce7825322cd50))
* **lint:** ui and internal_processing ([8113856](https://github.com/dont-be-evil-company/kulala.nvim/commit/8113856fb0e8fd6a4545c06c03d5582ac906d39d))
* **tree-sitter:** add sub-module ([e483050](https://github.com/dont-be-evil-company/kulala.nvim/commit/e483050a54eb9d70ef733b06e129a8da8b3f1780))
* **ui:** markdown and indentation ([8efd731](https://github.com/dont-be-evil-company/kulala.nvim/commit/8efd7314704f07f9ec9ee76fe5d465b6a6ce9493))

## [6.9.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.9.1...v6.9.2) (2026-06-09)

## [6.9.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.9.0...v6.9.1) (2026-06-05)

## [6.9.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.8.1...v6.9.0) (2026-06-05)

## [6.8.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.8.0...v6.8.1) (2026-06-03)

### Bug Fixes

* **lsp:** return request_id from in-process LSP server ([44f997f](https://github.com/dont-be-evil-company/kulala.nvim/commit/44f997f8ffdf4e0e86d7ad3856f43e6593218aa8))

## [6.8.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.7.0...v6.8.0) (2026-06-02)

### Bug Fixes

* **ci:** add missing neovim dep ([d4f653d](https://github.com/dont-be-evil-company/kulala.nvim/commit/d4f653db4440dce8e2525749e7b34f32f4c27745))
* **ci:** hopefully it installs this tiie 🙈 ([fd1299b](https://github.com/dont-be-evil-company/kulala.nvim/commit/fd1299b9ff9a4b068e70ffdd3fd378cf257db29b))
* **ci:** install neovim from github releases ([b908b0c](https://github.com/dont-be-evil-company/kulala.nvim/commit/b908b0c7a1fbe56b6ec5af75d6f30abd8a57034b))
* **ci:** install tree-sitter-cli ([0a3a24e](https://github.com/dont-be-evil-company/kulala.nvim/commit/0a3a24ef7d72843ff8546d0109f91be8bdac9f7d))
* **ci:** install-ci.sh ([a79bf88](https://github.com/dont-be-evil-company/kulala.nvim/commit/a79bf8892f04914b5d27cef44a1663d3b8a1856c))
* **ci:** install-ci.sh ([ea4d238](https://github.com/dont-be-evil-company/kulala.nvim/commit/ea4d23864ca4b70c67cad1c87c72b0a48440c6dc))
* **ci:** update node gh action ([e43f4d8](https://github.com/dont-be-evil-company/kulala.nvim/commit/e43f4d85c9cd57b0638cd557a1cf141fb5ef670b))
* **ci:** use pre-compiled binary ([e3465e9](https://github.com/dont-be-evil-company/kulala.nvim/commit/e3465e975a9cf34bff21db97d66c407e6ab07a8a))
* **lsp:** lsp attaching to everything instead of just http scripts/files ([cc31bca](https://github.com/dont-be-evil-company/kulala.nvim/commit/cc31bcaa8a9b21ce8e04b73c7969409958142632))

## [6.7.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.6.2...v6.7.0) (2026-05-31)

### Features

* **graphql:** add graphql lsp support ([6c1ce42](https://github.com/dont-be-evil-company/kulala.nvim/commit/6c1ce42686853dd0bfb4cbf3685b8ade2a969af7))
* **ui:** winbar scroll & register kulala_ui as markdown in ts ([1a39809](https://github.com/dont-be-evil-company/kulala.nvim/commit/1a398090e8842611468cf74debe8b87bda31a240))

### Bug Fixes

* **dx:** skip version check if kulala_core path is set ([8507b91](https://github.com/dont-be-evil-company/kulala.nvim/commit/8507b9197e2933eca9f5ba8414993de4779c071e))
* **minit:** fix minit ([cb46fd5](https://github.com/dont-be-evil-company/kulala.nvim/commit/cb46fd58409414f05ce22054b3aaf71b4863c04d))
* **test:** move to minitest and cleanup old tests ([e053f84](https://github.com/dont-be-evil-company/kulala.nvim/commit/e053f847eccbe08b601c34aba335dfd5fe2e3e32))

## [6.6.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.6.1...v6.6.2) (2026-05-30)

### Bug Fixes

* **tree-sitter:** remove print statement ([3e6374d](https://github.com/dont-be-evil-company/kulala.nvim/commit/3e6374dc407781c3507854f537c7dfd649fa0a10))
* **tree-sitter:** scripts parsing ([6397ad2](https://github.com/dont-be-evil-company/kulala.nvim/commit/6397ad2406995d5ceb061ba04677f7a96fcfb953))

## [6.6.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.6.0...v6.6.1) (2026-05-30)

### Bug Fixes

* **oauth:** optional client secret for password grant ([03dfc20](https://github.com/dont-be-evil-company/kulala.nvim/commit/03dfc20f0571803ca418c2a81b6f46c2bb0e2cc4))
* **tree-sitter:** fix initial tree-sitter parser loading ([dfc6d17](https://github.com/dont-be-evil-company/kulala.nvim/commit/dfc6d175298f739aeabbd63bbb8eff1ebd4359e4))
* **ui:** wrong ft for http buf ([1f45ad8](https://github.com/dont-be-evil-company/kulala.nvim/commit/1f45ad8f5819f3a0792e9fb13fbf0457f3c53b8f))

## [6.6.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.5.0...v6.6.0) (2026-05-29)

### Features

* **lsp:** enhance diagnostics and LSP integration ([0a3a9b6](https://github.com/dont-be-evil-company/kulala.nvim/commit/0a3a9b60da955ca961f548b174945b940ff979d9))
* **ui:** use own kulala_ui ft ([bccba0c](https://github.com/dont-be-evil-company/kulala.nvim/commit/bccba0c4b21557ee916a82268c8993e9a84276b9))

## [6.5.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.4.0...v6.5.0) (2026-05-28)

### Features

* **lsp, lua-scripts:** Offload lsp to core and fix lua scripts ([7d60be1](https://github.com/dont-be-evil-company/kulala.nvim/commit/7d60be1f091cc40a64d5a14b926d060b205fc24b))

## [6.4.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.3.1...v6.4.0) (2026-05-28)

### Bug Fixes

* **tree-sitter:** build on windows ([f4c5fe7](https://github.com/dont-be-evil-company/kulala.nvim/commit/f4c5fe7ff5d936f1b74e70cdd1a6d073236b9087))

## [6.3.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.3.0...v6.3.1) (2026-05-27)

## [6.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.2.0...v6.3.0) (2026-05-26)

### Features

* shared-blocks, nop url, implicit first request, and more ([87601dd](https://github.com/dont-be-evil-company/kulala.nvim/commit/87601ddef556f21888c59e0a2713873ad73f9c29))

### Bug Fixes

* **ci:** add safe-guard for version mismatch on release script ([adacb40](https://github.com/dont-be-evil-company/kulala.nvim/commit/adacb40946fbc5be0ed9447afa4b1e2389b68570))
* **ci:** broken tests ci ([09e2661](https://github.com/dont-be-evil-company/kulala.nvim/commit/09e26614aae7add1d554719d2a9bf0b57f794640))
* **ci:** refactor ci workflows ([d6d9c33](https://github.com/dont-be-evil-company/kulala.nvim/commit/d6d9c333ff2292151a8d1c05addaec794fef62ae))
* **docs:** remove develop branch from README.md ([ca474b8](https://github.com/dont-be-evil-company/kulala.nvim/commit/ca474b85ef1241da3333f5ea4c774467de0f0b28))

## [6.2.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.1.0...v6.2.0) (2026-05-25)

### Features

* **backend, scripts:** bump backend and support script failures ([b92e6e9](https://github.com/dont-be-evil-company/kulala.nvim/commit/b92e6e962fc84a0e6b82d4c8e25c1f460f08289f))

## [6.1.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.7...v6.1.0) (2026-05-24)

### Features

* **backend:** kulala-vscode-restclient-compat + kulala-curl-* passthrough ([5809fe0](https://github.com/dont-be-evil-company/kulala.nvim/commit/5809fe0b599bba8a125adf02922b535303f78b01))

## [6.0.7](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.6...v6.0.7) (2026-05-24)

### Bug Fixes

* **cookies:** localhost secure cookies are supported by core now ([0e4c49e](https://github.com/dont-be-evil-company/kulala.nvim/commit/0e4c49ec24d0ed7603e71e88c0f73bdb14a7ca1a))

## [6.0.6](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.5...v6.0.6) (2026-05-23)

### Bug Fixes

* **body:** default to json ([bfe3b3a](https://github.com/dont-be-evil-company/kulala.nvim/commit/bfe3b3aa1a928d998dbf1036c92272b53a81c261))

## [6.0.5](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.4...v6.0.5) (2026-05-23)

### Bug Fixes

* **body:** stringify js objects with no content-type ([ddbb626](https://github.com/dont-be-evil-company/kulala.nvim/commit/ddbb626c0af5de633757ddf7af686a9ba4fe0b13))

## [6.0.4](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.3...v6.0.4) (2026-05-22)

### Bug Fixes

* **body:** send body with no content-type ([ac15e02](https://github.com/dont-be-evil-company/kulala.nvim/commit/ac15e02ee3fc8b18d53c88f492db416b9f36f668))
* **cookies:** allow sending secure cookies to localhost ([f9f4871](https://github.com/dont-be-evil-company/kulala.nvim/commit/f9f487197c63ac06add570a606bcfd36dda3644e))

## [6.0.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.2...v6.0.3) (2026-05-22)

### Bug Fixes

* **backend:** backend bump for jetbrains multipart/form-data fix ([3e6a9cd](https://github.com/dont-be-evil-company/kulala.nvim/commit/3e6a9cd163956397156b4222209437648837a68d))

## [6.0.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.1...v6.0.2) (2026-05-22)

### Bug Fixes

* **backend:** backend has a multipart/form-data fix ([713cf9d](https://github.com/dont-be-evil-company/kulala.nvim/commit/713cf9d86f2b91620a9b9598ca2234793b5ecb50))
* **replay:** don't filter replays by success status ([aa05c85](https://github.com/dont-be-evil-company/kulala.nvim/commit/aa05c854cc46e235aa24684d0521719570ea489e))

## [6.0.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v6.0.0...v6.0.1) (2026-05-21)

### Features

* **variables:** re-add shared headers in http-client.env.json ([99f8c47](https://github.com/dont-be-evil-company/kulala.nvim/commit/99f8c4739a9ddc8914da29328307084b8bbc80b3))

### Bug Fixes

* **default_env, multi-reqs:** default_env and multi-reqs/shared-flow ([c5daa1e](https://github.com/dont-be-evil-company/kulala.nvim/commit/c5daa1ef1e4d8382bd01a807ef83d0bab1e20e5c))
* **ui:** body view uses response ft again ([96ab8bc](https://github.com/dont-be-evil-company/kulala.nvim/commit/96ab8bceff5d64feb2ff61ee20205962bb956482))

## [6.0.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.3.4...v6.0.0) (2026-05-20)

## [5.3.4](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.3.3...v5.3.4) (2026-02-08)

### Features

* **docs:** change schema url in examples to getkulala.net domain ([#783](https://github.com/dont-be-evil-company/kulala.nvim/issues/783)) ([b36aff6](https://github.com/dont-be-evil-company/kulala.nvim/commit/b36aff673915391e415d4acc7c90ca6ca6891750))

### Bug Fixes

* revert grammar changes ([#740](https://github.com/dont-be-evil-company/kulala.nvim/issues/740)) ([c328aeb](https://github.com/dont-be-evil-company/kulala.nvim/commit/c328aeb219c4b77106917dd2698c90ea9657281b))

## [5.3.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.3.2...v5.3.3) (2025-09-14)

### Features

* graphql, formatter, parser improvements and fixes ([#637](https://github.com/dont-be-evil-company/kulala.nvim/issues/637)) ([cb43b6b](https://github.com/dont-be-evil-company/kulala.nvim/commit/cb43b6b62b6e1c7ca901fce6a40d17814bd63b46)), references [#638](https://github.com/dont-be-evil-company/kulala.nvim/issues/638) [#642](https://github.com/dont-be-evil-company/kulala.nvim/issues/642)

### Bug Fixes

* **formatter:** do not error on missing formatters ([#632](https://github.com/dont-be-evil-company/kulala.nvim/issues/632)) ([44547a3](https://github.com/dont-be-evil-company/kulala.nvim/commit/44547a3b7f07c5097edf794b9f7aa99dfca931ed))
* **formatter:** script indentation ([#658](https://github.com/dont-be-evil-company/kulala.nvim/issues/658)) ([1695bdf](https://github.com/dont-be-evil-company/kulala.nvim/commit/1695bdfc87e2af737bec034cd4cd2d11098a22fd))

## [5.3.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.3.1...v5.3.2) (2025-07-20)

### Features

* kulala_http in markdown blocks, syntax hl, diagnostics + fixes ([#600](https://github.com/dont-be-evil-company/kulala.nvim/issues/600)) ([48e1400](https://github.com/dont-be-evil-company/kulala.nvim/commit/48e1400425fad0f18abf13a66937ed27d3e78461)), references [#613](https://github.com/dont-be-evil-company/kulala.nvim/issues/613)
* **parser:** infer Content-Type from body, [@secret](https://github.com/secret) metadata, create http-client.env + fixes ([#621](https://github.com/dont-be-evil-company/kulala.nvim/issues/621)) ([2169f27](https://github.com/dont-be-evil-company/kulala.nvim/commit/2169f274b36c7191e065e27bcf2760d0ce10f02c)), references [#618](https://github.com/dont-be-evil-company/kulala.nvim/issues/618)

### Bug Fixes

* **parser:** add nvim_treesitter/main compatibility ([#592](https://github.com/dont-be-evil-company/kulala.nvim/issues/592)) ([34beb95](https://github.com/dont-be-evil-company/kulala.nvim/commit/34beb95b14dab60ef0e7e54bf38c12d98067544a))

## [5.3.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.3.0...v5.3.1) (2025-06-19)

### Features

* **export:** Postman exporter, fix:(import) autodetect format ([#560](https://github.com/dont-be-evil-company/kulala.nvim/issues/560)) ([4ac30bb](https://github.com/dont-be-evil-company/kulala.nvim/commit/4ac30bb62c0db120ca3412b8dd52736da37959a3))
* import/export Postman ([#574](https://github.com/dont-be-evil-company/kulala.nvim/issues/574)) ([f174f64](https://github.com/dont-be-evil-company/kulala.nvim/commit/f174f645b0f6d078c2210791e2415e588c1690ad))
* **parser:** integrate kulala_http TS parser ([#583](https://github.com/dont-be-evil-company/kulala.nvim/issues/583)) ([8530e91](https://github.com/dont-be-evil-company/kulala.nvim/commit/8530e916c8b410a311ec3718ed77018aae57cc28))
* **scripts:** resolve NODE_PATH to nearest node_modules, add  node_path_resolver to options ([#577](https://github.com/dont-be-evil-company/kulala.nvim/issues/577)) ([93c9fba](https://github.com/dont-be-evil-company/kulala.nvim/commit/93c9fba4d98e069a662f20677d3ba3dc7fc7ac31)), references [#581](https://github.com/dont-be-evil-company/kulala.nvim/issues/581)

## [5.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.2.0...v5.3.0) (2025-05-23)

### Features

* CLI/CI, LSP formatter, JQ live filter, Client Credentials basic auth ([#507](https://github.com/dont-be-evil-company/kulala.nvim/issues/507)) ([41a1d92](https://github.com/dont-be-evil-company/kulala.nvim/commit/41a1d92bd37a03237295b4965c4a5c55b2c3d47e))
* **fzf:** make env select work with fzf ([#479](https://github.com/dont-be-evil-company/kulala.nvim/issues/479)) ([f2a5d94](https://github.com/dont-be-evil-company/kulala.nvim/commit/f2a5d94d4fe5f67707bf8a36331fdd803044c051))
* oauth improvements, [@curl-data-urlencode](https://github.com/curl-data-urlencode), various fixes ([#532](https://github.com/dont-be-evil-company/kulala.nvim/issues/532)) ([529136e](https://github.com/dont-be-evil-company/kulala.nvim/commit/529136e1ef7dbfb977a4ca1430c912e71fdba93b))
* **scripting:** add request.iteration() - current count of replays ([#550](https://github.com/dont-be-evil-company/kulala.nvim/issues/550)) ([f853463](https://github.com/dont-be-evil-company/kulala.nvim/commit/f853463e29e2a8cc28ea6bb40449b2378ed59a94))

### Bug Fixes

* **docs:** links ([bb8ae11](https://github.com/dont-be-evil-company/kulala.nvim/commit/bb8ae11e8122d50c80f4b71a01391df963d932bf))
* fix winbar highlights ([#474](https://github.com/dont-be-evil-company/kulala.nvim/issues/474)) ([90645ea](https://github.com/dont-be-evil-company/kulala.nvim/commit/90645ea1057001b89d60ef7f22503699da9f7bfc))
* **parser:** allow GRAPHQL method ([#552](https://github.com/dont-be-evil-company/kulala.nvim/issues/552)) ([e449742](https://github.com/dont-be-evil-company/kulala.nvim/commit/e44974298c2df6d431f848f2ed9d8cf7aa39b25c))
* post-release fixes ([#472](https://github.com/dont-be-evil-company/kulala.nvim/issues/472)) ([52fa0f4](https://github.com/dont-be-evil-company/kulala.nvim/commit/52fa0f45e7df736fd8a78f6635437ce328aac61f))
* remove keymaps prefix for custom keymaps ([#511](https://github.com/dont-be-evil-company/kulala.nvim/issues/511)) ([943f3e6](https://github.com/dont-be-evil-company/kulala.nvim/commit/943f3e694bb9003df1143dabc2cb7d21dfadc13b))
* **scripts:** lua asserts with nested keys ([#518](https://github.com/dont-be-evil-company/kulala.nvim/issues/518)) ([3301b2e](https://github.com/dont-be-evil-company/kulala.nvim/commit/3301b2e65cc98e3ea6ed824034d802951f453720))
* various fixes ([#490](https://github.com/dont-be-evil-company/kulala.nvim/issues/490)) ([99c3086](https://github.com/dont-be-evil-company/kulala.nvim/commit/99c30862c2dd49115d34697fcd7f826e243893ab))
* **vimdocs:** add missing permissions ([3de2622](https://github.com/dont-be-evil-company/kulala.nvim/commit/3de2622fa1bb2b4f4544945ee015a9096ae16f4a))

## [5.2.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.1.0...v5.2.0) (2025-04-14)

### Features

* [@curl-flags](https://github.com/curl-flags) - pre-request and global ([#451](https://github.com/dont-be-evil-company/kulala.nvim/issues/451)) ([97a50aa](https://github.com/dont-be-evil-company/kulala.nvim/commit/97a50aaeb5c2438e80b3da27f1314a9bf3c3ceb0))
* $auth.token for Oauth2 support ([#430](https://github.com/dont-be-evil-company/kulala.nvim/issues/430)) ([aa2aecc](https://github.com/dont-be-evil-company/kulala.nvim/commit/aa2aecc3573fd055d0bbea856dc1cee8eb84ab1d))
* add GRAPHQL method support ([#423](https://github.com/dont-be-evil-company/kulala.nvim/issues/423)) ([e4c749e](https://github.com/dont-be-evil-company/kulala.nvim/commit/e4c749e7ed5f35ddbb4fb87c70820f19fb17b470))
* add import and run commands ([#426](https://github.com/dont-be-evil-company/kulala.nvim/issues/426)) ([bde8be1](https://github.com/dont-be-evil-company/kulala.nvim/commit/bde8be17bf9983f302442ec91ad443f651bdef47))
* add news popup ([#429](https://github.com/dont-be-evil-company/kulala.nvim/issues/429)) ([1c9bb81](https://github.com/dont-be-evil-company/kulala.nvim/commit/1c9bb81df89fbd2603695fc0b039a53956d12b0f))
* add support for multiline URLs ([#439](https://github.com/dont-be-evil-company/kulala.nvim/issues/439)) ([bdf9204](https://github.com/dont-be-evil-company/kulala.nvim/commit/bdf920487e11eec76d8279863c145a0e8ed0d2d4))
* add win_opts config option ([#417](https://github.com/dont-be-evil-company/kulala.nvim/issues/417)) ([ce2ac68](https://github.com/dont-be-evil-company/kulala.nvim/commit/ce2ac6847ac7ed49d50900b3f7958e807e4ee856))
* **doc:** add runnable http demo ([#427](https://github.com/dont-be-evil-company/kulala.nvim/issues/427)) ([b2e24f2](https://github.com/dont-be-evil-company/kulala.nvim/commit/b2e24f2e343ee848f99b74f6c868c282eb883218))
* **import:** add nested import support ([#435](https://github.com/dont-be-evil-company/kulala.nvim/issues/435)) ([2370c38](https://github.com/dont-be-evil-company/kulala.nvim/commit/2370c3804ae3eccbf4366ed3a6472761986d0d06))
* LSP ([#466](https://github.com/dont-be-evil-company/kulala.nvim/issues/466)) ([4066f38](https://github.com/dont-be-evil-company/kulala.nvim/commit/4066f3881032b1f5b37c825007ae250091d54a8e))
* Lua scripting ([#454](https://github.com/dont-be-evil-company/kulala.nvim/issues/454)) ([48e4995](https://github.com/dont-be-evil-company/kulala.nvim/commit/48e4995dccb6ab647ddc7ceeb0017cd25c2a8b98))
* **ui:** add autocompletion ([#453](https://github.com/dont-be-evil-company/kulala.nvim/issues/453)) ([7dfd600](https://github.com/dont-be-evil-company/kulala.nvim/commit/7dfd60000e9e5578af710b85c31942a5361666e2))
* **ui:** Request progress and Request interrupt ([#449](https://github.com/dont-be-evil-company/kulala.nvim/issues/449)) ([4d8d524](https://github.com/dont-be-evil-company/kulala.nvim/commit/4d8d5249f3a32622085b9c10573860f91593fac5))
* URL line - comply with IntelliJ spec ([#424](https://github.com/dont-be-evil-company/kulala.nvim/issues/424)) ([2bb115d](https://github.com/dont-be-evil-company/kulala.nvim/commit/2bb115dfb01c9c29348d8b331bda2856f771d84b))
* **virt_text:** use 'combine' to blend with cursorline ([#432](https://github.com/dont-be-evil-company/kulala.nvim/issues/432)) ([f9daf1d](https://github.com/dont-be-evil-company/kulala.nvim/commit/f9daf1df015aac94350b3f20c26ce43a9e0009be))
* Websockets support ([#428](https://github.com/dont-be-evil-company/kulala.nvim/issues/428)) ([747bf31](https://github.com/dont-be-evil-company/kulala.nvim/commit/747bf31a289ca2443a1dec732f123a7f22b7f0cd))

### Bug Fixes

* **build-toc:** remove unused import ([289a0b3](https://github.com/dont-be-evil-company/kulala.nvim/commit/289a0b3faa4b4905b9797f0f8ed28fc82aec7b53))
* config and docs update ([#440](https://github.com/dont-be-evil-company/kulala.nvim/issues/440)) ([67cc8bd](https://github.com/dont-be-evil-company/kulala.nvim/commit/67cc8bdbe0e912a92124e44a29cb8b779cd0d5c8))
* Js update fix ([#412](https://github.com/dont-be-evil-company/kulala.nvim/issues/412)) ([cf9c0d6](https://github.com/dont-be-evil-company/kulala.nvim/commit/cf9c0d65ee019034d5264dabec4bb2bce10eb619))
* **parser:** replay and comments ([#422](https://github.com/dont-be-evil-company/kulala.nvim/issues/422)) ([85cfc79](https://github.com/dont-be-evil-company/kulala.nvim/commit/85cfc79c9e1f3000446fca37ab7f61529be77c2a))
* shell escape in copy/paste to/from curl ([#463](https://github.com/dont-be-evil-company/kulala.nvim/issues/463)) ([a1d3336](https://github.com/dont-be-evil-company/kulala.nvim/commit/a1d33369b9c695d34c3d2b9acee383f44a7a4323))
* **ui:** do not set signs if signcolumn not used ([#425](https://github.com/dont-be-evil-company/kulala.nvim/issues/425)) ([7defd36](https://github.com/dont-be-evil-company/kulala.nvim/commit/7defd3663afce220c7de4fe0af6deaece90faef8))
* **ui:** fallback to select if no telescope/snacks ([#446](https://github.com/dont-be-evil-company/kulala.nvim/issues/446)) ([ffdfd42](https://github.com/dont-be-evil-company/kulala.nvim/commit/ffdfd428018fd00a1d17bdccebbc70ba5cf48778))
* **ui:** winbar keymaps init ([#434](https://github.com/dont-be-evil-company/kulala.nvim/issues/434)) ([791b885](https://github.com/dont-be-evil-company/kulala.nvim/commit/791b8850e8faf0588955cf531a0817195bcab737))
* **ui:** winbar keymaps init ([#434](https://github.com/dont-be-evil-company/kulala.nvim/issues/434)) ([#437](https://github.com/dont-be-evil-company/kulala.nvim/issues/437)) ([d69fbb2](https://github.com/dont-be-evil-company/kulala.nvim/commit/d69fbb27b370bd5e431b9ac66760d7cdbfd28b6d))
* use screen size instead of win size for float ([#414](https://github.com/dont-be-evil-company/kulala.nvim/issues/414)) ([12f2ce7](https://github.com/dont-be-evil-company/kulala.nvim/commit/12f2ce784c31fbba748bf230e048e1764626f3fa))
* User-Agent headers ([#465](https://github.com/dont-be-evil-company/kulala.nvim/issues/465)) ([5fddda6](https://github.com/dont-be-evil-company/kulala.nvim/commit/5fddda621630fef17e09cec930d2e307f4a5a138))

## [5.1.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v5.0.0...v5.1.0) (2025-03-09)

### Features

* Cookie: header support ([#394](https://github.com/dont-be-evil-company/kulala.nvim/issues/394)) ([476bc17](https://github.com/dont-be-evil-company/kulala.nvim/commit/476bc17cec2265ad54b4245d5be4196e64a007eb))
* replace vars in external json ([#397](https://github.com/dont-be-evil-company/kulala.nvim/issues/397)) ([3360aaa](https://github.com/dont-be-evil-company/kulala.nvim/commit/3360aaa50b1b41966f8ab1c131b6428ab8ab0f6c))

### Bug Fixes

* **curl parser:** multiline body ([#383](https://github.com/dont-be-evil-company/kulala.nvim/issues/383)) ([#384](https://github.com/dont-be-evil-company/kulala.nvim/issues/384)) ([e6c0dd3](https://github.com/dont-be-evil-company/kulala.nvim/commit/e6c0dd334997cfb4feeded8338c4c06f7bec98a6))
* open UI in the same tab as request buffer ([#400](https://github.com/dont-be-evil-company/kulala.nvim/issues/400)) ([20595e8](https://github.com/dont-be-evil-company/kulala.nvim/commit/20595e88f223d1f2f9f0b49e0907ac78631463ea))
* **parser:** body not overriding computed_body anymore ([#399](https://github.com/dont-be-evil-company/kulala.nvim/issues/399)) ([381bc1a](https://github.com/dont-be-evil-company/kulala.nvim/commit/381bc1a0b91fc03b22ea2dda78a46d117f2ce585))
* **parser:** correctly handle empty lines ([#395](https://github.com/dont-be-evil-company/kulala.nvim/issues/395)) ([b396a12](https://github.com/dont-be-evil-company/kulala.nvim/commit/b396a122d19218bcb4be2028817bcfbb7b2460f7))
* update docs ([#401](https://github.com/dont-be-evil-company/kulala.nvim/issues/401)) ([bf74da3](https://github.com/dont-be-evil-company/kulala.nvim/commit/bf74da37518f84097a83593214ad835b908eae8c))
* use nowait for keymaps ([#402](https://github.com/dont-be-evil-company/kulala.nvim/issues/402)) ([13521c0](https://github.com/dont-be-evil-company/kulala.nvim/commit/13521c0ff302cbd2e5258c5d079b867ea96bc432))

## [5.0.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.11.0...v5.0.0) (2025-02-21)

### Bug Fixes

* **docs:** related to latest refactoring ([#390](https://github.com/dont-be-evil-company/kulala.nvim/issues/390)) ([66f127c](https://github.com/dont-be-evil-company/kulala.nvim/commit/66f127c916a828d342846a9bbccc5e928178a5ef))
* **parser:** redirect response with overwrite enabled ([#387](https://github.com/dont-be-evil-company/kulala.nvim/issues/387)) ([dc5e1f9](https://github.com/dont-be-evil-company/kulala.nvim/commit/dc5e1f94d71d3cca3c729a8d0259820b96822172))
* **tests:** replace hard-coded kulala version ([#388](https://github.com/dont-be-evil-company/kulala.nvim/issues/388)) ([168fb1c](https://github.com/dont-be-evil-company/kulala.nvim/commit/168fb1ce4f7ac93c482632ffc369d99ee16a616a))

## [4.11.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.10.0...v4.11.0) (2025-02-20)

### Features

* add custom response handler ([#326](https://github.com/dont-be-evil-company/kulala.nvim/issues/326)) ([#381](https://github.com/dont-be-evil-company/kulala.nvim/issues/381)) ([b75348c](https://github.com/dont-be-evil-company/kulala.nvim/commit/b75348c32733ecaea6dd9b43f85bac85c0e75470))
* add default keymaps ([#358](https://github.com/dont-be-evil-company/kulala.nvim/issues/358)) ([841bf45](https://github.com/dont-be-evil-company/kulala.nvim/commit/841bf4532b114f31b03b9a9d305967d5620701bf))
* add grpc support ([#378](https://github.com/dont-be-evil-company/kulala.nvim/issues/378)) ([276df23](https://github.com/dont-be-evil-company/kulala.nvim/commit/276df23e571243416ece18d1043e98d728fa008a))
* **docs:** update codeowners ([#359](https://github.com/dont-be-evil-company/kulala.nvim/issues/359)) ([11107e6](https://github.com/dont-be-evil-company/kulala.nvim/commit/11107e6572a05405da1f4124943416fdecfe99a8))
* **docs:** update various docs ([#374](https://github.com/dont-be-evil-company/kulala.nvim/issues/374)) ([070bf2d](https://github.com/dont-be-evil-company/kulala.nvim/commit/070bf2d12f5b11df82854b11792b51c95b744623))
* **parser:** replace variables also in header name ([#357](https://github.com/dont-be-evil-company/kulala.nvim/issues/357)) ([3e46f68](https://github.com/dont-be-evil-company/kulala.nvim/commit/3e46f68ab0567744b626d526add5b1c09556bd93))
* store/scroll response history ([#376](https://github.com/dont-be-evil-company/kulala.nvim/issues/376)) ([684cc57](https://github.com/dont-be-evil-company/kulala.nvim/commit/684cc5743c486fa4a06169ed5659c7d3d8d14ccb))

### Bug Fixes

* allow async for run_all() ([#368](https://github.com/dont-be-evil-company/kulala.nvim/issues/368)) ([#371](https://github.com/dont-be-evil-company/kulala.nvim/issues/371)) ([0dc1a9b](https://github.com/dont-be-evil-company/kulala.nvim/commit/0dc1a9bef028880905d0aeb85862b9066a48aff2))
* do no reopen win in another tab ([#379](https://github.com/dont-be-evil-company/kulala.nvim/issues/379)) ([#380](https://github.com/dont-be-evil-company/kulala.nvim/issues/380)) ([3ae070f](https://github.com/dont-be-evil-company/kulala.nvim/commit/3ae070f24979d68c8db9df1fb60b8989ba6c3214))
* paste from curl ([#364](https://github.com/dont-be-evil-company/kulala.nvim/issues/364)) ([#365](https://github.com/dont-be-evil-company/kulala.nvim/issues/365)) ([a83a150](https://github.com/dont-be-evil-company/kulala.nvim/commit/a83a15017c49e05a1f8da5592c1e2eabc7e15ea9))
* Send one-off request async ([#368](https://github.com/dont-be-evil-company/kulala.nvim/issues/368)) ([#370](https://github.com/dont-be-evil-company/kulala.nvim/issues/370)) ([93aa416](https://github.com/dont-be-evil-company/kulala.nvim/commit/93aa41655c0ff4fd6f53d17c92512c907c223e59))
* **str_var_parser:** binary data handling ([#360](https://github.com/dont-be-evil-company/kulala.nvim/issues/360)) ([ba6e632](https://github.com/dont-be-evil-company/kulala.nvim/commit/ba6e6320c8bd9a4188a3f06c52022a3c2dabb710))
* to allow run_all() for visually selected lines ([#325](https://github.com/dont-be-evil-company/kulala.nvim/issues/325)) ([#352](https://github.com/dont-be-evil-company/kulala.nvim/issues/352)) ([571bdf5](https://github.com/dont-be-evil-company/kulala.nvim/commit/571bdf59162a5562f218374bbec1ce807c9e03bd))

## [4.10.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.9.0...v4.10.0) (2025-02-06)

### Features

* show variable values on hover ([#220](https://github.com/dont-be-evil-company/kulala.nvim/issues/220)) ([6ff0478](https://github.com/dont-be-evil-company/kulala.nvim/commit/6ff0478df57f1592a09b2b839f345944a04be76c))
* **ui:** flash requests ([#356](https://github.com/dont-be-evil-company/kulala.nvim/issues/356)) ([c4dc857](https://github.com/dont-be-evil-company/kulala.nvim/commit/c4dc857f3dc09da9f23c9aa4acfe8b9294b33b7f))

### Bug Fixes

* **cmd:** loading icon not shown ([#355](https://github.com/dont-be-evil-company/kulala.nvim/issues/355)) ([847bc7a](https://github.com/dont-be-evil-company/kulala.nvim/commit/847bc7ad1b00ec05dfd6a8b9fd7308d7408958d2))
* **docs:** wrong href for usage manual ([#349](https://github.com/dont-be-evil-company/kulala.nvim/issues/349)) ([f921b8b](https://github.com/dont-be-evil-company/kulala.nvim/commit/f921b8bc3c54afc74a13eb417f453bc1b377c4ef))
* **ui:** highlights ([cb27010](https://github.com/dont-be-evil-company/kulala.nvim/commit/cb27010578b7b00cf4ce166031fbc5f9c1746992))

## [4.9.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.8.0...v4.9.0) (2025-02-05)

### Features

* **docs:** update GraphQL documentation ([a8a2659](https://github.com/dont-be-evil-company/kulala.nvim/commit/a8a2659cac4a7db7ea6e3ddfae6fb48cd4d6f47f))

### Bug Fixes

* result panel didn't show after call ([#312](https://github.com/dont-be-evil-company/kulala.nvim/issues/312)) ([9892a7c](https://github.com/dont-be-evil-company/kulala.nvim/commit/9892a7c355359f27aa309161ebabd1d0ced8e9ae))

## [4.8.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.7.0...v4.8.0) (2025-02-01)

### Features

* **assets:** inline all possible assets ([#343](https://github.com/dont-be-evil-company/kulala.nvim/issues/343)) ([7a5aff0](https://github.com/dont-be-evil-company/kulala.nvim/commit/7a5aff0889e0d0e53c3606822c08a5447a08ff0e))
* **docs:** update LICENSE ([d6d3f61](https://github.com/dont-be-evil-company/kulala.nvim/commit/d6d3f61a58e6fcad40b91545c84afb4364e65a69))

### Bug Fixes

* parsing errors when doing run_all() [#337](https://github.com/dont-be-evil-company/kulala.nvim/issues/337) ([#342](https://github.com/dont-be-evil-company/kulala.nvim/issues/342)) ([44297aa](https://github.com/dont-be-evil-company/kulala.nvim/commit/44297aa64af30a296051d433cd4aad674c2ea43e))

## [4.7.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.6.0...v4.7.0) (2025-01-27)

### Features

* **api:** add `after_next_request`. ([#341](https://github.com/dont-be-evil-company/kulala.nvim/issues/341)) ([e7ce284](https://github.com/dont-be-evil-company/kulala.nvim/commit/e7ce28440c14f09e0f3ee81342cd11fc660f96d9))
* **float:** add `q_to_close_float` config option ([#340](https://github.com/dont-be-evil-company/kulala.nvim/issues/340)) ([3961c69](https://github.com/dont-be-evil-company/kulala.nvim/commit/3961c69f57cca94bfb6a0cc2e0f911c774d34269)), closes [#324](https://github.com/dont-be-evil-company/kulala.nvim/issues/324)

## [4.6.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.5.1...v4.6.0) (2025-01-26)

### Features

* **docker:** make docker images public ([#339](https://github.com/dont-be-evil-company/kulala.nvim/issues/339)) ([84a1541](https://github.com/dont-be-evil-company/kulala.nvim/commit/84a15410eafaa986c5f09bb578e5a8f77338813a))

### Bug Fixes

* **ci:** use correct docker image ([4aa23e4](https://github.com/dont-be-evil-company/kulala.nvim/commit/4aa23e47fdd827412702b322b9ccf75b9d9755b2))
* **ci:** use correct docker image ([16fd161](https://github.com/dont-be-evil-company/kulala.nvim/commit/16fd161d7fe9a5af4a736b6bc696cd5d0cd717d4))
* **ci:** use correct docker image ([84850be](https://github.com/dont-be-evil-company/kulala.nvim/commit/84850be9520ace3d36ed97584fb828e3fa5ce680))

## [4.5.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.5.0...v4.5.1) (2025-01-21)

### Bug Fixes

* **format:** fix function format params ([#336](https://github.com/dont-be-evil-company/kulala.nvim/issues/336)) ([04cc4a3](https://github.com/dont-be-evil-company/kulala.nvim/commit/04cc4a36807516cd277022e529aeed95636c279d))

## [4.5.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.4.1...v4.5.0) (2025-01-18)

### Features

* **inspect:** show auth headers on inspect ([#333](https://github.com/dont-be-evil-company/kulala.nvim/issues/333)) ([d1d2a13](https://github.com/dont-be-evil-company/kulala.nvim/commit/d1d2a13ab2751a1c5afa1b6ec9a4270c139000b6))

### Bug Fixes

* change units in stats to be millseconds ([#318](https://github.com/dont-be-evil-company/kulala.nvim/issues/318)) ([c7efcd0](https://github.com/dont-be-evil-company/kulala.nvim/commit/c7efcd01afafae0ab68c2a77cd050b9795edd8ad))
* don't start request timer until after prompt responses are submitted ([#335](https://github.com/dont-be-evil-company/kulala.nvim/issues/335)) ([dcd7f94](https://github.com/dont-be-evil-company/kulala.nvim/commit/dcd7f94e849ee0a9564bf823dba4778c913d429b))

## [4.4.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.4.0...v4.4.1) (2024-11-07)

### Bug Fixes

* **scripts:** windows: js engine build and run ([#313](https://github.com/dont-be-evil-company/kulala.nvim/issues/313)) ([383defc](https://github.com/dont-be-evil-company/kulala.nvim/commit/383defc97f5516621875213768bd2287c84ced2e)), closes [#304](https://github.com/dont-be-evil-company/kulala.nvim/issues/304)

## [4.4.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.3.0...v4.4.0) (2024-11-03)

### Features

* **display_mode:** split or float ([#308](https://github.com/dont-be-evil-company/kulala.nvim/issues/308)) ([a3643b2](https://github.com/dont-be-evil-company/kulala.nvim/commit/a3643b228f23fde4a1026adb6a3efc3b22722e12)), closes [#300](https://github.com/dont-be-evil-company/kulala.nvim/issues/300)
* **parser:** huge req bodies + don't assume blobs ([#305](https://github.com/dont-be-evil-company/kulala.nvim/issues/305)) ([bc2eb2d](https://github.com/dont-be-evil-company/kulala.nvim/commit/bc2eb2d789bf2fe72e1d868c63a522e1c6733edf)), closes [#298](https://github.com/dont-be-evil-company/kulala.nvim/issues/298)
* **scripts:** install failure verbosity ([623a26a](https://github.com/dont-be-evil-company/kulala.nvim/commit/623a26aba7a19c0104ea61d583a86a64d99e1b44)), closes [#302](https://github.com/dont-be-evil-company/kulala.nvim/issues/302)

### Bug Fixes

* LICENSE + docusaurus notice ([9bfa4e9](https://github.com/dont-be-evil-company/kulala.nvim/commit/9bfa4e9ac82ca3429bd2edcc70e15623545c8d3f))
* **scratchpad:** noswapfile ([#286](https://github.com/dont-be-evil-company/kulala.nvim/issues/286)) ([d4d78b2](https://github.com/dont-be-evil-company/kulala.nvim/commit/d4d78b2acb483de4bd697898aec53eb3d2548d36))
* **scripts:** keep tmp dir tree ([#283](https://github.com/dont-be-evil-company/kulala.nvim/issues/283)) ([fb7e5d9](https://github.com/dont-be-evil-company/kulala.nvim/commit/fb7e5d9637ccacee9d920d20d569edae0a4c6fe0))
* space character problem when parsing content-type ([#310](https://github.com/dont-be-evil-company/kulala.nvim/issues/310)) ([70001fe](https://github.com/dont-be-evil-company/kulala.nvim/commit/70001fe85fa8cd127a9f82c2c0927015d694639c))
* **tmp:** use `stdpath('cache')` for tmp files ([#284](https://github.com/dont-be-evil-company/kulala.nvim/issues/284)) ([c7a2c79](https://github.com/dont-be-evil-company/kulala.nvim/commit/c7a2c793dca8509f9792e9d35d377de016c88a5b)), references [#282](https://github.com/dont-be-evil-company/kulala.nvim/issues/282)
* **treesitter:** show body on treesitter inspect ([#303](https://github.com/dont-be-evil-company/kulala.nvim/issues/303)) ([59787b2](https://github.com/dont-be-evil-company/kulala.nvim/commit/59787b26206a43c6f96760aee2cf9061701810ec))
* **winbar:** keybinds after session restore ([#307](https://github.com/dont-be-evil-company/kulala.nvim/issues/307)) ([164dc11](https://github.com/dont-be-evil-company/kulala.nvim/commit/164dc11d6e51e322b9310cfa9eefb873b9f53b1b)), closes [#295](https://github.com/dont-be-evil-company/kulala.nvim/issues/295)

### Reverts

* **quickfix:** folds not working in lazyvim ([#306](https://github.com/dont-be-evil-company/kulala.nvim/issues/306)) ([ac61243](https://github.com/dont-be-evil-company/kulala.nvim/commit/ac61243e1d17f438d64ca19c364723ddf857fd21))

## [4.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.2.0...v4.3.0) (2024-10-10)

### Features

* **search:** searching for named requests now ([#280](https://github.com/dont-be-evil-company/kulala.nvim/issues/280)) ([bfc6c10](https://github.com/dont-be-evil-company/kulala.nvim/commit/bfc6c10310dd539be8121a1073bcb526cc45b9ed))

### Bug Fixes

* **graphql:** add a Content-Type: application/json if not specified ([#277](https://github.com/dont-be-evil-company/kulala.nvim/issues/277)) ([f6a85b3](https://github.com/dont-be-evil-company/kulala.nvim/commit/f6a85b3885d5f34c1cc282b78176fbe16e1e52cb))
* **parser:** form-data + binary ([#278](https://github.com/dont-be-evil-company/kulala.nvim/issues/278)) ([7d8ccb3](https://github.com/dont-be-evil-company/kulala.nvim/commit/7d8ccb30279b0279310813e9010b0ef6644dbaa4))
* **ui:** folds not working in lazy ([#279](https://github.com/dont-be-evil-company/kulala.nvim/issues/279)) ([a543d6e](https://github.com/dont-be-evil-company/kulala.nvim/commit/a543d6e722ca9ffcd754a412764a70796d4be1c4))

## [4.2.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.1.1...v4.2.0) (2024-10-08)

### Features

* **scripts:** add request to post_request script ([#273](https://github.com/dont-be-evil-company/kulala.nvim/issues/273)) ([f7186ec](https://github.com/dont-be-evil-company/kulala.nvim/commit/f7186ec0909f820945f1cfb77bf83a12935f62d8))

## [4.1.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.1.0...v4.1.1) (2024-10-08)

### Features

* **ci:** testrunner clipboard support ([#267](https://github.com/dont-be-evil-company/kulala.nvim/issues/267)) ([7f95cd0](https://github.com/dont-be-evil-company/kulala.nvim/commit/7f95cd0687fd9cea8dcc3fec895f731890063631))
* **docs:** fix CODEOWNERS, add CODE_OF_CONDUCT & CONTRIBUTING ([#264](https://github.com/dont-be-evil-company/kulala.nvim/issues/264)) ([03f80f5](https://github.com/dont-be-evil-company/kulala.nvim/commit/03f80f5f739938e69c398517a629735938b783c1))
* **docs:** support json highlights ([e156929](https://github.com/dont-be-evil-company/kulala.nvim/commit/e156929cf409902496843b3a5259180f7bdbb019))

### Bug Fixes

* **docs:** typo in CONTRIBUTING ([#265](https://github.com/dont-be-evil-company/kulala.nvim/issues/265)) ([0c88376](https://github.com/dont-be-evil-company/kulala.nvim/commit/0c88376d5dbed269a69c6de764fcc798c3c1e200))
* **env:** selector without telescope ([#272](https://github.com/dont-be-evil-company/kulala.nvim/issues/272)) ([140e653](https://github.com/dont-be-evil-company/kulala.nvim/commit/140e6536a2b5033c78da4189164a603947febced))

## [4.1.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.0.4...v4.1.0) (2024-10-06)

### Features

* **ci:** add tag script ([#263](https://github.com/dont-be-evil-company/kulala.nvim/issues/263)) ([2a19eb4](https://github.com/dont-be-evil-company/kulala.nvim/commit/2a19eb4e052e7186c4b89c3c5ad9b3bf5c9bf60f))
* **scripts:** add `request.body.getComputed()` ([#262](https://github.com/dont-be-evil-company/kulala.nvim/issues/262)) ([3407b68](https://github.com/dont-be-evil-company/kulala.nvim/commit/3407b681b2227d1cd10489107ebbe61b2b0ede11))

## [4.0.4](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.0.3...v4.0.4) (2024-10-05)

### Bug Fixes

* **scripts:** remove lowercase headers access ([#261](https://github.com/dont-be-evil-company/kulala.nvim/issues/261)) ([757f87c](https://github.com/dont-be-evil-company/kulala.nvim/commit/757f87c903611d16dc5ae57be607c01a68da0711))
* **utils:** remove print ([c7d258d](https://github.com/dont-be-evil-company/kulala.nvim/commit/c7d258d925c113ef75dd35e4d4376c9f4500155d))

## [4.0.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v4.0.0...v4.0.3) (2024-10-04)

### Features

* **headers:** use as supplied + support multiple headers ([#260](https://github.com/dont-be-evil-company/kulala.nvim/issues/260)) ([a408fcf](https://github.com/dont-be-evil-company/kulala.nvim/commit/a408fcf79ad4a4cc8792de168dde4d8ac51ce2b8))
* **parser:** streamline globals ([#259](https://github.com/dont-be-evil-company/kulala.nvim/issues/259)) ([39ce81e](https://github.com/dont-be-evil-company/kulala.nvim/commit/39ce81edc135c21800d03333eb1e7625b8d03f70))

### Bug Fixes

* **fs:** join_paths on windows ([#258](https://github.com/dont-be-evil-company/kulala.nvim/issues/258)) ([77a8ad3](https://github.com/dont-be-evil-company/kulala.nvim/commit/77a8ad311dff5c17da60b055c7cbb42f03eebb84))
* resolve "no such file or directory" error in scratchpad ([#254](https://github.com/dont-be-evil-company/kulala.nvim/issues/254)) ([67447c2](https://github.com/dont-be-evil-company/kulala.nvim/commit/67447c2d35cd2ce73796b410cc4b14847f04a779))
* **scripts:** only process if not empty ([#257](https://github.com/dont-be-evil-company/kulala.nvim/issues/257)) ([50d0318](https://github.com/dont-be-evil-company/kulala.nvim/commit/50d031807f9ba88a0c896d5998d229e13d93c2ca))

## [4.0.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.8.0...v4.0.0) (2024-10-01)

### Features

* add json schema for http-client.env.json ([#243](https://github.com/dont-be-evil-company/kulala.nvim/issues/243)) ([558337b](https://github.com/dont-be-evil-company/kulala.nvim/commit/558337bb8f88d26354259098dae3805982cdec34))
* **ci:** add docs linter ([#234](https://github.com/dont-be-evil-company/kulala.nvim/issues/234)) ([ddf3781](https://github.com/dont-be-evil-company/kulala.nvim/commit/ddf3781727482c5e76e2e91cc533b4e4bf39dd6e))
* **ci:** add linter ([#231](https://github.com/dont-be-evil-company/kulala.nvim/issues/231)) ([45ac960](https://github.com/dont-be-evil-company/kulala.nvim/commit/45ac960d50d98967dc1a8e99b5c7a066baf2bbd7))
* **config:** make curl path configurable ([#226](https://github.com/dont-be-evil-company/kulala.nvim/issues/226)) ([ea1b276](https://github.com/dont-be-evil-company/kulala.nvim/commit/ea1b27677084ff1f855645269d7cc3b301926a0b))

### Bug Fixes

* **docs:** example ([#227](https://github.com/dont-be-evil-company/kulala.nvim/issues/227)) ([37977a4](https://github.com/dont-be-evil-company/kulala.nvim/commit/37977a4eb6a50e0ec53c6890a7fbd74f97a80409))
* **form:** fix binary multipart-form-data ([#230](https://github.com/dont-be-evil-company/kulala.nvim/issues/230)) ([1bc28a9](https://github.com/dont-be-evil-company/kulala.nvim/commit/1bc28a90c389ea83634c3e1a77524c637829db62))
* **from_curl:** improve heuristic and recognize curl_path too ([#238](https://github.com/dont-be-evil-company/kulala.nvim/issues/238)) ([4a08292](https://github.com/dont-be-evil-company/kulala.nvim/commit/4a0829288842b2f6d5dec82670c68b219d9ae84c))
* **gql:** introspection curl path ([#235](https://github.com/dont-be-evil-company/kulala.nvim/issues/235)) ([8adfa27](https://github.com/dont-be-evil-company/kulala.nvim/commit/8adfa272ecea55ee08215edc909271c70888e7e4))
* **health:** support curl_path in a healthcheck ([#237](https://github.com/dont-be-evil-company/kulala.nvim/issues/237)) ([1a016d1](https://github.com/dont-be-evil-company/kulala.nvim/commit/1a016d170a78cf0fbd6495bae56176aca615b43b))
* **parser:** handle exception when no reqs found ([#250](https://github.com/dont-be-evil-company/kulala.nvim/issues/250)) ([b950b88](https://github.com/dont-be-evil-company/kulala.nvim/commit/b950b889da6cbfc71d3c181ae93ff398d88842b7))
* **shlex:** make split function more robust ([#229](https://github.com/dont-be-evil-company/kulala.nvim/issues/229)) ([dd6a549](https://github.com/dont-be-evil-company/kulala.nvim/commit/dd6a5498e6e588d3550c869010b3882eb4fa783c))
* **ui:** treesitter foldexpr calculate not work ([#249](https://github.com/dont-be-evil-company/kulala.nvim/issues/249)) ([bfbb7b2](https://github.com/dont-be-evil-company/kulala.nvim/commit/bfbb7b2a476ef44e7b01292b3ffe47ab733d4fe6)), references [#128](https://github.com/dont-be-evil-company/kulala.nvim/issues/128)

## [3.8.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.7.0...v3.8.0) (2024-09-09)

### Features

* **checkhealth:** support for neovim :checkhealth feature ([#215](https://github.com/dont-be-evil-company/kulala.nvim/issues/215)) ([813a1d2](https://github.com/dont-be-evil-company/kulala.nvim/commit/813a1d20cb8eb975c073c04c0761a59420d52bd8))
* **ci:** test support via plenary test harness ([#212](https://github.com/dont-be-evil-company/kulala.nvim/issues/212)) ([64b0465](https://github.com/dont-be-evil-company/kulala.nvim/commit/64b046590f10f15ce447d5dfae35e97fff5226a5))

### Bug Fixes

* **docs:** wrong json format ([8bff6eb](https://github.com/dont-be-evil-company/kulala.nvim/commit/8bff6ebf15b9eafb0e4069d26d16a2a03bd122b5))
* **fs:** non_http_file detection ([f5b0a69](https://github.com/dont-be-evil-company/kulala.nvim/commit/f5b0a6961ffbaca1f932c673f970407ce19c0704))
* **parser:** trimming lines caused troubles ([#221](https://github.com/dont-be-evil-company/kulala.nvim/issues/221)) ([4bc33af](https://github.com/dont-be-evil-company/kulala.nvim/commit/4bc33af4e6a4857c28cb691ee05600fb7912410f))
* **ui/parser:** remove unused variable, remove nil warnings ([#210](https://github.com/dont-be-evil-company/kulala.nvim/issues/210)) ([18fd207](https://github.com/dont-be-evil-company/kulala.nvim/commit/18fd207fbf01ba311f2c4bc7b9ad60b1cad633ec))

## [3.7.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.6.0...v3.7.0) (2024-09-01)

### Features

* **from_curl:** import HTTP spec from curl command line ([#186](https://github.com/dont-be-evil-company/kulala.nvim/issues/186)) ([8a532b1](https://github.com/dont-be-evil-company/kulala.nvim/commit/8a532b1ec6448cd136b7080c0bcffdbeb4617723))
* **parser:** from fenced-code-blocks ([#206](https://github.com/dont-be-evil-company/kulala.nvim/issues/206)) ([fb02494](https://github.com/dont-be-evil-company/kulala.nvim/commit/fb024941621457dfb80834be08e4ab026443e1f0))
* **vars:** add prompt variables ([#203](https://github.com/dont-be-evil-company/kulala.nvim/issues/203)) ([2fdcd31](https://github.com/dont-be-evil-company/kulala.nvim/commit/2fdcd318dd9e7f8fe1ce7ab46fba78bb04546e4d))

### Bug Fixes

* **prompt-vars:** run parser after prompt vars ([#204](https://github.com/dont-be-evil-company/kulala.nvim/issues/204)) ([cff78ce](https://github.com/dont-be-evil-company/kulala.nvim/commit/cff78ce71931bc2cd26a6aa0df5d4544f96859fd))

## [3.6.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.5.0...v3.6.0) (2024-08-31)

### Features

* **copy:** clean and fix ([#174](https://github.com/dont-be-evil-company/kulala.nvim/issues/174)) ([6607024](https://github.com/dont-be-evil-company/kulala.nvim/commit/6607024a69c3bfc5d61ea6533ea590d3c29b5fea))
* **env:** get_selected_env() ([68d261d](https://github.com/dont-be-evil-company/kulala.nvim/commit/68d261dd322a3139309b53e1ce0c791d74fc639f))
* **parser:** add inspect ([#175](https://github.com/dont-be-evil-company/kulala.nvim/issues/175)) ([38cac91](https://github.com/dont-be-evil-company/kulala.nvim/commit/38cac91b52fd571054c13803d601680cb4ee9080))
* **req-blocks:** optional comments ([#195](https://github.com/dont-be-evil-company/kulala.nvim/issues/195)) ([5358a28](https://github.com/dont-be-evil-company/kulala.nvim/commit/5358a28935f363eeb68f1d6b19cb1ec71d039a21))
* **scripts:** print output ([#177](https://github.com/dont-be-evil-company/kulala.nvim/issues/177)) ([163cd33](https://github.com/dont-be-evil-company/kulala.nvim/commit/163cd33177fabe3ac65edecaf3e6523e1f8017cc))
* **style:** Standardize the code format ([#187](https://github.com/dont-be-evil-company/kulala.nvim/issues/187)) ([c2de6c1](https://github.com/dont-be-evil-company/kulala.nvim/commit/c2de6c1faa48a6a251b00d9420a6d74971b0ecaf))
* **telescope:** add telescope sorter ([#190](https://github.com/dont-be-evil-company/kulala.nvim/issues/190)) ([635cdbc](https://github.com/dont-be-evil-company/kulala.nvim/commit/635cdbc984b06c6b83321e62a0a9094d93a625c1))

### Bug Fixes

* **fs:** Compatible with "/" and "\\" ([#173](https://github.com/dont-be-evil-company/kulala.nvim/issues/173)) ([721f0ce](https://github.com/dont-be-evil-company/kulala.nvim/commit/721f0cee90be2712225dafe2d0be97b95abac2c9))
* **fs:** join_paths ([c22842c](https://github.com/dont-be-evil-company/kulala.nvim/commit/c22842c3b92dca9d842a36b57b0b7911a5bdc235))
* **scripts:** node_modules path local to script.cwd ([#171](https://github.com/dont-be-evil-company/kulala.nvim/issues/171)) ([77c5624](https://github.com/dont-be-evil-company/kulala.nvim/commit/77c5624c12d0c7a8ea28d2e9731933f6112fab78))
* **stats:** blank string + run_all ([#200](https://github.com/dont-be-evil-company/kulala.nvim/issues/200)) ([9f31a39](https://github.com/dont-be-evil-company/kulala.nvim/commit/9f31a39a3114654e8345a3037f01228f41bef728))
* **ts:** error on startup ([#196](https://github.com/dont-be-evil-company/kulala.nvim/issues/196)) ([6c4ab0c](https://github.com/dont-be-evil-company/kulala.nvim/commit/6c4ab0cb6020136ae9889bb2e116263b7e7eab51))

### Reverts

* Revert "parse requests with treesitter (#181)" (#182) ([7649576](https://github.com/dont-be-evil-company/kulala.nvim/commit/7649576ca459146658b4c415d1a320bbedc3f564)), references [#181](https://github.com/dont-be-evil-company/kulala.nvim/issues/181) [#182](https://github.com/dont-be-evil-company/kulala.nvim/issues/182)

## [3.5.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.4.0...v3.5.0) (2024-08-20)

### Features

* add `run_all()` ([#166](https://github.com/dont-be-evil-company/kulala.nvim/issues/166)) ([d92ac74](https://github.com/dont-be-evil-company/kulala.nvim/commit/d92ac746f7af4119423b5ee321a2da21b999ade2))
* support AWS-SigV4 authentication ([#165](https://github.com/dont-be-evil-company/kulala.nvim/issues/165)) ([3def89d](https://github.com/dont-be-evil-company/kulala.nvim/commit/3def89d7819fdcc8bd3ec576ad682ae6622fbfdc))

### Bug Fixes

* **auth:** ntlm and negotiate ([#169](https://github.com/dont-be-evil-company/kulala.nvim/issues/169)) ([a2a8e82](https://github.com/dont-be-evil-company/kulala.nvim/commit/a2a8e82fa9172e644804e7a015858ec97f106140))
* **authparser:** already encoded strings ([#168](https://github.com/dont-be-evil-company/kulala.nvim/issues/168)) ([6706d84](https://github.com/dont-be-evil-company/kulala.nvim/commit/6706d848ddb60a0cf1a7c115de3af60ffad83d17))

## [3.4.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.3.0...v3.4.0) (2024-08-17)

### Features

* add cookie parser ([#152](https://github.com/dont-be-evil-company/kulala.nvim/issues/152)) ([67bac82](https://github.com/dont-be-evil-company/kulala.nvim/commit/67bac827e4497d33f814a8696a24ddd171e9c784))

## [3.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.2.1...v3.3.0) (2024-08-17)

### Features

* add api ([#150](https://github.com/dont-be-evil-company/kulala.nvim/issues/150)) ([e75cbd0](https://github.com/dont-be-evil-company/kulala.nvim/commit/e75cbd0dc1a4801f1070bfdeb0bbc4d4b25e57ce))

### Bug Fixes

* **gql:** introspection ([#149](https://github.com/dont-be-evil-company/kulala.nvim/issues/149)) ([f74298f](https://github.com/dont-be-evil-company/kulala.nvim/commit/f74298f28a14cd4fcf6d913fc5635e2ffb675817))

## [3.2.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.2.0...v3.2.1) (2024-08-15)

### Bug Fixes

* set_selected_env() does nothing ([#145](https://github.com/dont-be-evil-company/kulala.nvim/issues/145)) ([eb03136](https://github.com/dont-be-evil-company/kulala.nvim/commit/eb03136797d5374b0142b8f7e4438334387fa183))

## [3.2.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.1.4...v3.2.0) (2024-08-15)

## [3.1.4](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.1.3...v3.1.4) (2024-08-15)

### Bug Fixes

* **lualine:** default env ([601bf6f](https://github.com/dont-be-evil-company/kulala.nvim/commit/601bf6f4ba7ffb34d3b3480982d8123a9c89bae4))
* winbar + default_view ([#141](https://github.com/dont-be-evil-company/kulala.nvim/issues/141)) ([a578d95](https://github.com/dont-be-evil-company/kulala.nvim/commit/a578d9544171f43d97bdad0b3c320cd365c70cae)), closes [#139](https://github.com/dont-be-evil-company/kulala.nvim/issues/139)

## [3.1.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.1.2...v3.1.3) (2024-08-14)

### Bug Fixes

* **env:** parser ([#138](https://github.com/dont-be-evil-company/kulala.nvim/issues/138)) ([966658a](https://github.com/dont-be-evil-company/kulala.nvim/commit/966658af457638dd4e9a5fc3ed9a685862ff68e7)), closes [#129](https://github.com/dont-be-evil-company/kulala.nvim/issues/129)

## [3.1.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.1.1...v3.1.2) (2024-08-14)

### Bug Fixes

* **winbar:** keymappings not working anymore ([#137](https://github.com/dont-be-evil-company/kulala.nvim/issues/137)) ([b158c04](https://github.com/dont-be-evil-company/kulala.nvim/commit/b158c04d1fc0e4023ba51a804ba296d06d5030fc))

## [3.1.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.1.0...v3.1.1) (2024-08-14)

## [3.1.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.0.3...v3.1.0) (2024-08-14)

### Features

* add option to configure split direction ([#134](https://github.com/dont-be-evil-company/kulala.nvim/issues/134)) ([c63ad1b](https://github.com/dont-be-evil-company/kulala.nvim/commit/c63ad1bfd45b794a3b6c7ad5e727578768c25909))

## [3.0.3](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.0.2...v3.0.3) (2024-08-14)

## [3.0.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.0.1...v3.0.2) (2024-08-14)

## [3.0.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v3.0.0...v3.0.1) (2024-08-14)

### Bug Fixes

* **ui:** replace buffer when content changes ([#130](https://github.com/dont-be-evil-company/kulala.nvim/issues/130)) ([2f40eac](https://github.com/dont-be-evil-company/kulala.nvim/commit/2f40eac8fad85adb76cea2503a091a1cc1f7be30)), references [#128](https://github.com/dont-be-evil-company/kulala.nvim/issues/128)

## [3.0.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.11.0...v3.0.0) (2024-08-12)

### Features

* **gql:** add schema download ([#125](https://github.com/dont-be-evil-company/kulala.nvim/issues/125)) ([1949b75](https://github.com/dont-be-evil-company/kulala.nvim/commit/1949b75056428138f08af8a0308bb1de24d24627))
* show both headers and body ([f462adc](https://github.com/dont-be-evil-company/kulala.nvim/commit/f462adc1426682cdd2bae590dd492a74e1af2f9c))

### Bug Fixes

* check the existance of both headers and body files ([3ce216e](https://github.com/dont-be-evil-company/kulala.nvim/commit/3ce216e2c4270312f6ae30686b1c471661eb0fd8))
* **lint:** stylua ([#126](https://github.com/dont-be-evil-company/kulala.nvim/issues/126)) ([6905f47](https://github.com/dont-be-evil-company/kulala.nvim/commit/6905f47b2134d2d3f51e1b82821dd0532f7ceb6c))
* split headers into key value at first colon ([9f30238](https://github.com/dont-be-evil-company/kulala.nvim/commit/9f302382c20444ff110837eba20887eb8a5b0321))

## [2.11.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.10.0...v2.11.0) (2024-08-11)

### Features

* add winbar for result buffer ([57e6d82](https://github.com/dont-be-evil-company/kulala.nvim/commit/57e6d8206ff32d3dd7abc3670c190a9c7d5bd593))
* **parser:** graphql -> same syntax as vscode ([c801f8c](https://github.com/dont-be-evil-company/kulala.nvim/commit/c801f8cd5dbeaf5d32771303c5a41feef452dedb))
* **parser:** use magic gql vscode header as fallback ([517bec7](https://github.com/dont-be-evil-company/kulala.nvim/commit/517bec706877689c3568ef8b1bf4224b5b271040))

### Bug Fixes

* check winbar before call toggle_headers ([d344873](https://github.com/dont-be-evil-company/kulala.nvim/commit/d34487366d292d3f3051f931477e7b8983e6d6b9))
* check winbar in M.open and M.replay functions ([2654db9](https://github.com/dont-be-evil-company/kulala.nvim/commit/2654db97c04397d5a56f34bc3832a5056de45bf4))
* **parser:** req-vars array access ([06042a7](https://github.com/dont-be-evil-company/kulala.nvim/commit/06042a771ae05f957dc5de79e841f5f92bdb6e03)), closes [#114](https://github.com/dont-be-evil-company/kulala.nvim/issues/114)
* **search:** fallback ([73b7c67](https://github.com/dont-be-evil-company/kulala.nvim/commit/73b7c67ddf5c3d06592b0ed108ac5b047100b703)), closes [#100](https://github.com/dont-be-evil-company/kulala.nvim/issues/100)

## [2.10.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.9.0...v2.10.0) (2024-08-05)

### Features

* add search() ([4083d4c](https://github.com/dont-be-evil-company/kulala.nvim/commit/4083d4c462ba946397e1d8f75d563a075914347a))
* **parser:** lazy-eval doc-variables ([c7ee4bf](https://github.com/dont-be-evil-company/kulala.nvim/commit/c7ee4bf2f0100bdb15a6aa41f8dc1553433bec0a))
* **parser:** named-requests + request-variables ([30752aa](https://github.com/dont-be-evil-company/kulala.nvim/commit/30752aa30f937a42c292cd13787187fbfe4f4fa9))
* **ui:** add scratchpad ([533453b](https://github.com/dont-be-evil-company/kulala.nvim/commit/533453b4d949b2e52301656a936d2a0db627acd2)), closes [#81](https://github.com/dont-be-evil-company/kulala.nvim/issues/81)

### Bug Fixes

* **ci:** fix deploy docs workflow ([e951cc3](https://github.com/dont-be-evil-company/kulala.nvim/commit/e951cc3231b899e9ed0dd3f6ac5b6f7880a01303))

## [2.8.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.8.1...v2.8.2) (2024-08-01)

### Features

* **parser:** add env-header-key meta tag ([293e4bc](https://github.com/dont-be-evil-company/kulala.nvim/commit/293e4bcc82b8d7f1d8af3ea0c5af656c696c842a)), closes [#87](https://github.com/dont-be-evil-company/kulala.nvim/issues/87)

### Bug Fixes

* **env:** early return causing nil env table error ([cb828db](https://github.com/dont-be-evil-company/kulala.nvim/commit/cb828db500077b4a948f1dcff793d10bca8dc289))
* **fs:** find nearest file ([6caf08c](https://github.com/dont-be-evil-company/kulala.nvim/commit/6caf08c159c3f093fb575f458ac1621dfbcaf5ce)), closes [#88](https://github.com/dont-be-evil-company/kulala.nvim/issues/88)

## [2.7.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.7.0...v2.7.1) (2024-07-30)

### Features

* add `.copy()` function ([c45e3df](https://github.com/dont-be-evil-company/kulala.nvim/commit/c45e3df93faaf04f98f2c0ba7405a3818d2e2dfc)), closes [#67](https://github.com/dont-be-evil-company/kulala.nvim/issues/67)
* **ci:** add documentation release label ([e9fbca1](https://github.com/dont-be-evil-company/kulala.nvim/commit/e9fbca193dd913c3d8a978264838a2d4ed977bea))
* **env:** add DEFAULT_HEADERS ([6de07a5](https://github.com/dont-be-evil-company/kulala.nvim/commit/6de07a51846c644198a1ea4960eecb5d13a6c2c0)), closes [#60](https://github.com/dont-be-evil-company/kulala.nvim/issues/60)
* **parser:** add [@file-to-variable](https://github.com/file-to-variable) meta-tag ([6365721](https://github.com/dont-be-evil-company/kulala.nvim/commit/63657214d806e9e47ede6e1423f203f946c344f6))
* **ui:** add `close()` function ([edb6185](https://github.com/dont-be-evil-company/kulala.nvim/commit/edb6185a3fbb0d84bfe741ba5910c5bf68a9ebae)), closes [#75](https://github.com/dont-be-evil-company/kulala.nvim/issues/75)

### Bug Fixes

* **docs:** broken link ([2b97833](https://github.com/dont-be-evil-company/kulala.nvim/commit/2b978334ba20be30f8f909ced589bfef3f0553dd))
* **docs:** fix README links to docs ([5b713be](https://github.com/dont-be-evil-company/kulala.nvim/commit/5b713befb3aa5b078de8c65495bea6739ee109c9))
* **fs:** avoid infinite loop searching parent dir ([945fab4](https://github.com/dont-be-evil-company/kulala.nvim/commit/945fab4f4596d1b5591d7f1f206a9547c0675f44))
* **parser:** don't set data when body is nil ([b48abd8](https://github.com/dont-be-evil-company/kulala.nvim/commit/b48abd8eb50e00fcf9446312ccb85a7fed6a693f))

## [2.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v2.2.2...v2.3.0) (2024-07-16)

### Features

* add internal processing ([01a3bdd](https://github.com/dont-be-evil-company/kulala.nvim/commit/01a3bdd5664ae4382a917626233b0421e573ab21))
* **jumps:** add jumps ([50a52c9](https://github.com/dont-be-evil-company/kulala.nvim/commit/50a52c91f950a6e57bace6979da6e673d1cbb97a))
* move to docusaurus ([f06fabe](https://github.com/dont-be-evil-company/kulala.nvim/commit/f06fabe308f96e2dc4d74385e8cea86f85cc4321))
* **parser:** add inline graphql support ([aad5831](https://github.com/dont-be-evil-company/kulala.nvim/commit/aad58311a57635bbdaae5d51203bcce3b012269d))
* **parser:** add inline graphql support ([36ced58](https://github.com/dont-be-evil-company/kulala.nvim/commit/36ced581e527545aa2db25a0127455fba55fd2f3))
* **parser:** simplify content-type if-else ([4f55db6](https://github.com/dont-be-evil-company/kulala.nvim/commit/4f55db6acdf10dde5c1be8d95624463810bfffeb))
* **parser:** verbosity on fail ([08479e4](https://github.com/dont-be-evil-company/kulala.nvim/commit/08479e4106ce69ca7d4b935a6262ffdc35905a3a)), closes [#45](https://github.com/dont-be-evil-company/kulala.nvim/issues/45)
* **version:** add kulala.version() ([ca7ef51](https://github.com/dont-be-evil-company/kulala.nvim/commit/ca7ef510a0b9308c8ed66696926adcc13ac6f6d0))

### Bug Fixes

* allow other content types to be used ([2f1b352](https://github.com/dont-be-evil-company/kulala.nvim/commit/2f1b3527a35b0f70c1ebec88c9fc5a6cc50af5e9))
* **autocmd:** add augroup ([571e439](https://github.com/dont-be-evil-company/kulala.nvim/commit/571e43938096e043ea3d088e4ee817729d6841d8))
* **ci:** build docs ([f865a81](https://github.com/dont-be-evil-company/kulala.nvim/commit/f865a8177b7edb2e5a885f89a16e6381b815373b))
* **ci:** chmod +x build-docs.sh ([364c6c5](https://github.com/dont-be-evil-company/kulala.nvim/commit/364c6c5db4f9d9fea9e399def804812ef510347f))
* **cmd:** make success var local ([1a223d0](https://github.com/dont-be-evil-company/kulala.nvim/commit/1a223d003f53f0b47996f1a3e29b7827d64d03e7))
* **formatter:** fix formatting not getting applied ([2212625](https://github.com/dont-be-evil-company/kulala.nvim/commit/2212625e19a7eb2d379bc9ab6a76ba69e07ab550))
* **parser:** document variables with underscores ([a5e6fe9](https://github.com/dont-be-evil-company/kulala.nvim/commit/a5e6fe9cfa3e2321938645effbf392ee07c7d7d9))

## [1.6.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.6.1...v1.6.2) (2024-07-11)

### Bug Fixes

* **env:** accessing env-variables ([1c20926](https://github.com/dont-be-evil-company/kulala.nvim/commit/1c2092610a987efb38caa9e80d2bcaff43073aa2))

## [1.6.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.6.0...v1.6.1) (2024-07-10)

### Bug Fixes

* **env:** dotenv with = in value should work now ([9d59626](https://github.com/dont-be-evil-company/kulala.nvim/commit/9d596267480c8e3e8b766d83c8a91afd8759f883))

## [1.6.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.5.2...v1.6.0) (2024-07-10)

### Bug Fixes

* config-reset ([fbd533e](https://github.com/dont-be-evil-company/kulala.nvim/commit/fbd533e3cd414842d435094dcf868ba67f17d008)), closes [#37](https://github.com/dont-be-evil-company/kulala.nvim/issues/37)
* error-cases + reformat + versionbump ([9904d82](https://github.com/dont-be-evil-company/kulala.nvim/commit/9904d82170de6563a0d4e4bb8e274e95ad84c1fe))
* **fs:** infinite loop on windows ([dc4ebe0](https://github.com/dont-be-evil-company/kulala.nvim/commit/dc4ebe08d6558a3486106ec9d3b5dcfc859013ed))

## [1.5.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.4.0...v1.5.0) (2024-07-04)

### Features

* add CODEOWNERS ([66e0ec0](https://github.com/dont-be-evil-company/kulala.nvim/commit/66e0ec01c7ca47cbeeeadd45d12ca56b02d85760))
* add custom additional curl opts ([6d93f19](https://github.com/dont-be-evil-company/kulala.nvim/commit/6d93f19b90111a760ab41839dd6b9bfbe752c14b)), closes [#29](https://github.com/dont-be-evil-company/kulala.nvim/issues/29)
* add icons config ([b024a12](https://github.com/dont-be-evil-company/kulala.nvim/commit/b024a12bc841862088f175a29ba71af704ec6c34))
* **docs:** clarify a lot of things ([a79aa02](https://github.com/dont-be-evil-company/kulala.nvim/commit/a79aa02e701a1c463841290e44a3b0e462e3c7f3))

### Bug Fixes

* **fs-utils:** loop until root dir in windows ([bdbeab7](https://github.com/dont-be-evil-company/kulala.nvim/commit/bdbeab72ea1190f86fba9c50c40728847c60b17a))

## [1.3.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.2.2...v1.3.0) (2024-07-01)

### Features

* formatters overridable in config ([35b011f](https://github.com/dont-be-evil-company/kulala.nvim/commit/35b011f39c38b8eaaec8c76f71c228ba65a62a80)), closes [#19](https://github.com/dont-be-evil-company/kulala.nvim/issues/19)

## [1.2.2](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.2.1...v1.2.2) (2024-06-30)

### Bug Fixes

* **parser:** external file handling ([ebeb7cb](https://github.com/dont-be-evil-company/kulala.nvim/commit/ebeb7cb13c54615641adbf3a70e79eb931ff26c9))

## [1.2.1](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.1.0...v1.2.1) (2024-06-29)

### Bug Fixes

* **parser:** default ft text instead of nil ([dcfc0d8](https://github.com/dont-be-evil-company/kulala.nvim/commit/dcfc0d803012e13e8540ff655873e334eb55580c))

## [1.1.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/v1.0.0...v1.1.0) (2024-06-29)

### Features

* add gh pages workflow ([9cb10c7](https://github.com/dont-be-evil-company/kulala.nvim/commit/9cb10c7d6051ed75c0e38220975de8ebdaefc0a0))
* add lualine support ([8c4e812](https://github.com/dont-be-evil-company/kulala.nvim/commit/8c4e81217ade786a1cf9f1be92a2ad7d1cef4eec)), closes [#16](https://github.com/dont-be-evil-company/kulala.nvim/issues/16)
* **env:** select envs from http-client.env.json ([ede579f](https://github.com/dont-be-evil-company/kulala.nvim/commit/ede579f6f40ee1571d2ffd53096f60b9722c315c)), closes [#15](https://github.com/dont-be-evil-company/kulala.nvim/issues/15)

## [1.0.0](https://github.com/dont-be-evil-company/kulala.nvim/compare/5113b1d56c6b4a4ae0cf1e4c4890bbdd35f697f6...v1.0.0) (2024-06-29)

### Features

* 1.0.0 is here ([0ced730](https://github.com/dont-be-evil-company/kulala.nvim/commit/0ced730d04c1efee7c40b85f40838ebba49cc4dc))
* add `.toggle_headers()` ([6bc759f](https://github.com/dont-be-evil-company/kulala.nvim/commit/6bc759fd52771092df91708f7dc740d23fd2350a))
* add bare variables support. ([752d4e6](https://github.com/dont-be-evil-company/kulala.nvim/commit/752d4e633530c3b7d09417e542b4ed2765031f0e))
* add discord server link ([7aec47d](https://github.com/dont-be-evil-company/kulala.nvim/commit/7aec47d586b2dc8867438eb57a35c71b31527b13))
* add docs ([2287cfc](https://github.com/dont-be-evil-company/kulala.nvim/commit/2287cfce289df61c30c1673f4d7f76562607001e))
* add jumps ([81df533](https://github.com/dont-be-evil-company/kulala.nvim/commit/81df53309d2378f8a7fa6805bf35b7bbf51fa835)), closes [#6](https://github.com/dont-be-evil-company/kulala.nvim/issues/6)
* add logo ([d601ea0](https://github.com/dont-be-evil-company/kulala.nvim/commit/d601ea097a555f0e9e923b2ff0ed8a4bb80bb4e7))
* add support for xml/html ([a8dae8d](https://github.com/dont-be-evil-company/kulala.nvim/commit/a8dae8dad467b98c52e0eb649c3b2e69af3fc5c9))
* alpha release ([5113b1d](https://github.com/dont-be-evil-company/kulala.nvim/commit/5113b1d56c6b4a4ae0cf1e4c4890bbdd35f697f6))
* **cmd:** if formatter not avail, use unformatted ([74107e6](https://github.com/dont-be-evil-company/kulala.nvim/commit/74107e6e39580b590cc7671ed2c83fd869f3e139)), references [#11](https://github.com/dont-be-evil-company/kulala.nvim/issues/11)
* **cmd:** save headers to tmp file ([0f94579](https://github.com/dont-be-evil-company/kulala.nvim/commit/0f94579282027a98f9a28c1a802cedb7e3b25de9)), references [#13](https://github.com/dont-be-evil-company/kulala.nvim/issues/13)

### Bug Fixes

* encode query params ([8017490](https://github.com/dont-be-evil-company/kulala.nvim/commit/8017490c6c2938946efca379bf67e94ce15aefdd)), closes [#8](https://github.com/dont-be-evil-company/kulala.nvim/issues/8)
* **formatter:** html ([4c849f2](https://github.com/dont-be-evil-company/kulala.nvim/commit/4c849f2e20a4dcff376a71763de55913107c66b6))
* on_term_ready firing multiple times ([f1cc401](https://github.com/dont-be-evil-company/kulala.nvim/commit/f1cc4017f0f48509daefcb440969f9a456b8a875))
* **parser:** fix json + graphql + http_version ([3f7bd18](https://github.com/dont-be-evil-company/kulala.nvim/commit/3f7bd1878f57294141d6f45b468a924ec9cc5529))
* **parser:** header + body values ([55d4c43](https://github.com/dont-be-evil-company/kulala.nvim/commit/55d4c43740dc36b10db0b53d4f68f70348d821d1))
* **parser:** header parsing of variables ([7bb9772](https://github.com/dont-be-evil-company/kulala.nvim/commit/7bb97727ab155777cb88cc7aae916796d47b9006))
* **parser:** lowercase headers ([a6c8fb7](https://github.com/dont-be-evil-company/kulala.nvim/commit/a6c8fb78553f9f9bda800f3e6bfbe80d32d953e6)), closes [#10](https://github.com/dont-be-evil-company/kulala.nvim/issues/10)
* **parser:** parse_string_variables ([8357ed3](https://github.com/dont-be-evil-company/kulala.nvim/commit/8357ed3dc683ebe9ec81ff72eb17260baf3e9588))
* **release-script:** set_version ([c70dbba](https://github.com/dont-be-evil-company/kulala.nvim/commit/c70dbba1feed694e63740217b017945c504956f7))
* **release:** missing git is dirty function ([cf37ab0](https://github.com/dont-be-evil-company/kulala.nvim/commit/cf37ab058c638584843926b398af561ce36af11b))
* **ui:** opening up buffers after close ([eb8a48f](https://github.com/dont-be-evil-company/kulala.nvim/commit/eb8a48f019afb9d11c8728c6dfaf12ad1628b2ea))
* variable sub in url ([780cae0](https://github.com/dont-be-evil-company/kulala.nvim/commit/780cae0f16fcfb97a31fa0791f049c381f000f26)), closes [#8](https://github.com/dont-be-evil-company/kulala.nvim/issues/8)

### Performance Improvements

* use normal buffer instead of terminal ([428dbeb](https://github.com/dont-be-evil-company/kulala.nvim/commit/428dbeb4d208208fcd3748bfa2e48702be4aa970))
