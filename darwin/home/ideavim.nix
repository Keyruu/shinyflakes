{...}: {
  home.file.".ideavimrc".text = /* vim */ ''
    let mapleader = " "

    set relativenumber
    set number
    set idearefactormode=keep
    set ideajoin
    set scrolloff=10
    set showmode
    set sneak
    set surround
    set easymotion
    " set commentary

    set ignorecase

    set NERDTree
    let g:NERDTreeMapActivateNode='l'
    let g:NERDTreeMapJumpParent='h'

    set which-key

    set timeoutlen=5000

    " edit ideavim config
    nnoremap <leader>vv :e ~/.ideavimrc<CR>
    nnoremap <leader>vs :source ~/.ideavimrc<CR>
    nmap <leader>vr <Action>(IdeaVim.ReloadVimRc.reload)

    " Window navigation
    sethandler <c-h> a:vim
    sethandler <c-l> a:vim
    sethandler <c-j> a:vim
    sethandler <c-k> a:vim
    nnoremap <c-h> <c-w>h
    nnoremap <c-l> <c-w>l
    nnoremap <c-j> <c-w>j
    nnoremap <c-k> <c-w>k

    nmap <Leader>\ :vsplit<CR>
    nmap <Leader>sh :vsplit<CR>
    nmap <Leader>- :split<CR>
    nmap <Leader>sv :split<CR>
    nmap <leader>fs <Action>(FileStructurePopup)

    " Clipboard
    vmap <leader>y "+y
    vmap <leader>Y "+Y
    vmap <leader>d "+d
    nmap <leader>y "+yy
    nmap <leader>p "+p
    nmap <leader>P "+P
    vmap <leader>p "+p
    vmap <leader>P "+P

    " Open Terminal
    nmap <Leader>t <Action>(ActivateTerminalToolWindow)

    " Open recent project dialog box
    nmap <Leader>m <Action>(ManageRecentProjects)

    " Mapping to mimic BufferExplorer
    " nmap <Leader>be <Action>(Switcher)
    nmap <Leader>fr <Action>(RecentFiles)
    nmap <Leader>ff <Action>(GotoFile)
    nmap <Leader>fc <Action>(GotoClass)
    nmap <Leader>fg <Action>(SearchEverywhere)
    nmap <Leader>fa <Action>(SearchEverywhere)
    nmap <Leader><Leader>b <Action>(RecentFiles)
    nmap <Leader>fp <Action>(FindInPath)

    " Press `f` to activate AceJump
    " map f <Action>(AceAction)
    " Press `F` to activate Target Mode
    " map F <Action>(AceTargetAction)
    " Press `g` to activate Line Mode
    " map g <Action>(AceLineAction)

    " Nerdtree want to be
    nmap <Leader>ef :NERDTreeFind<CR>
    nmap <Leader>et :NERDTreeToggle<CR>

    nmap <Leader>bp <Action>(ToggleLineBreakpoint)

    " Some Git Shortcuts for view status, pull, and branches
    " Mapping mimic Fugitive in my native vim

    nmap <Leader>gs <Action>(Git.Status)
    nmap <Leader>gc <Action>(CheckinProject)
    nmap <Leader>ga <Action>(Git.Add)
    nmap <Leader>gp <Action>(Git.Pull)
    nmap <Leader>gn <Action>(Annotate)
    nmap <Leader>gl <Action>(Git.Log)
    nmap <Leader>go <Action>(Github.Open.In.Browser)
    nmap <Leader>gb <Action>(Git.Branches)
    nmap <leader>gm <action>(Git.Menu)

    " Mapping Kubernetes stuff
    nmap <Leader>hu <Action>(Kubernetes.HelmDependencyUpdate)
    nmap <Leader>hl <Action>(Kubernetes.HelmLint)

    " Coding stuff
    nmap <Leader>cd <Action>(GotoDeclaration)
    nmap <Leader>cr <Action>(FindUsages)
    nmap <Leader>cu <Action>(FindUsages)
    nmap <Leader>ci <Action>(GotoImplementation)
    nmap <Leader>cc <Action>(CommentByLineComment)
    nmap <Leader>cq <Action>(QuickJavaDoc)
  '';
}
