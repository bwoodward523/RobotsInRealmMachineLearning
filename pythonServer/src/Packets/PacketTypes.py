class PacketTypes:
    # print("\n".join([re.search("\.toMessage\(.+?\)", x).group()[11:-1] + " = " + re.search("\.map\(.+?\)", x).group()[5:-1]  for x in tmp.split("\n")]))
    Create = 2
    PlayerShoot = 3
    Move = 4
    PlayerText = 5
    UpdateAck = 42
    InvSwap = 13
    UseItem = 14
    Hello = 16
    InvDrop = 18
    Pong = 22
    Load = 24
    SetCondition = 26
    Teleport = 27
    UsePortal = 28
    Buy = 30
    PlayerHit = 34
    EnemyHit = 35
    AoeAck = 36
    ShootAck = 37
    OtherHit = 38
    SquareHit = 39
    GotoAck = 40
    GroundDamage = 33
    ChooseName = 44
    CreateGuild = 46
    GuildRemove = 48
    GuildInvite = 49
    RequestTrade = 52
    RequestPartyInvite = 71
    ChangeTrade = 55
    AcceptTrade = 57
    CancelTrade = 58
    CheckCredits = 62
    Escape = 63
    JoinGuild = 66
    ChangeGuildRank = 67
    EditAccountList = 41
    QuestRedeem = 43
    MarketCommand = 76
    Failure = 0
    CreateSuccess = 1
    ServerPlayerShoot = 7
    Damage = 8
    Update = 9
    Notification = 69
    GlobalNotification = 11
    NewTick = 12
    ShowEffect = 15
    Goto = 17
    InvResult = 19
    Reconnect = 20
    Ping = 21
    MapInfo = 23
    Pic = 25
    Death = 29
    BuyResult = 31
    Aoe = 32
    AccountList = 42
    QuestObjId = 43
    NameResult = 45
    GuildResult = 47
    AllyShoot = 50
    EnemyShoot = 51
    TradeRequested = 53
    TradeStart = 54
    TradeChanged = 56
    TradeDone = 59
    TradeAccepted = 60
    ClientStat = 61
    File = 64
    InvitedToGuild = 65
    PlaySound = 68
    ImminentArenaWave = 87
    ReskinUnlock = 70
    SwitchMusic = 75
    MarketResult = 85
    Text = 6
    GroundTeleporter = 178
    GoToQuestRoom = 155
    LaunchRaid = 156
    SorForgeRequest = 159
    ForgeItem = 160
    AlertNotice = 163
    QoLAction = 165
    MarkRequest = 164
    UnboxRequest = 161
    RequestGamble = 167
    AcceptPartyInvite = 170
    ServerFull = 110
    QueuePing = 111
    SorForge = 158
    UnboxResultPacket = 162
    LootNotification = 171
    ShowTrials = 172
    TrialsRequest = 173
    PotionStorageInteraction = 174
    RenameItem = 175
    HomeDepotInteraction = 176
    HomeDepotResult = 177
    ClaimBattlePassItem = 179
    MissionsReceive = 180
    RespriteItem = 181
    ObsHealth = 182
    ObsPosition = 183
    ObsEnemyPositions = 184
    ObsProjectiles = 185
    ObsQuestPosition = 186
    ObsDeath = 187

    reverseDict = {x[1]: x[0] for x in locals().items() if isinstance(x[1], int)}