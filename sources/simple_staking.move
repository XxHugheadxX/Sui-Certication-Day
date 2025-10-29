module william::simple_staking {

    use sui::clock::{Self as clock, Clock};
    use sui::coin::{Self as coin, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self as balance, Balance};

    /// Estructura de staking individual de cada usuario
    public struct StakePosition has key, store {
        id: UID,
        owner: address,
        amount: u64,
        start_time: u64,
        reward_accum: u64,
        last_claim: u64,
        active: bool,
        coins: Option<Coin<SUI>>,
    }

    /// Configuración general del contrato
    public struct Config has key, store {
        id: UID,
        admin: address,
        reward_rate_daily: u64,
        rewards: Balance<SUI>,
    }

    /// Define el 'One-Time Witness' para la función 'init'
    public struct SIMPLE_STAKING has drop {}

    /// Inicializa el contrato
    fun init(_witness: SIMPLE_STAKING, ctx: &mut TxContext) {
        let cfg = Config {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            reward_rate_daily: 10, // 0.10%
            rewards: balance::zero(),
        };
        transfer::share_object(cfg);
    }

    /// Función de admin para depositar SUI en el fondo de recompensas
    public fun deposit_rewards(
        cfg: &mut Config, 
        coins: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == cfg.admin, 0);
        balance::join(&mut cfg.rewards, coin::into_balance(coins));
    }

    /// Permite al usuario realizar staking de tokens SUI
    public fun stake(
        coins: Coin<SUI>,
        clock_obj: &Clock,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&coins);
        let now = clock::timestamp_ms(clock_obj) / 1000;

        let pos = StakePosition {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            amount,
            start_time: now,
            reward_accum: 0,
            last_claim: now,
            active: true,
            coins: option::some(coins),
        };

        transfer::public_transfer(pos, tx_context::sender(ctx));
    }

    /// Calcula las recompensas acumuladas
    public fun calculate_rewards(pos: &StakePosition, cfg: &Config, clock_obj: &Clock): u64 {
        if (!pos.active) return 0;
        let now = clock::timestamp_ms(clock_obj) / 1000;
        if (now <= pos.last_claim) return pos.reward_accum;

        let days_passed = (now - pos.last_claim) / 86400;
        if (days_passed == 0) return pos.reward_accum;

        let reward = (pos.amount * cfg.reward_rate_daily * days_passed) / 10000;
        reward + pos.reward_accum
    }

    /// Reclamar únicamente la recompensa sin retirar el principal
    public fun claim(
        pos: &mut StakePosition,
        cfg: &mut Config,
        clock_obj: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(pos.active, 1);
        assert!(pos.owner == tx_context::sender(ctx), 2);

        let reward = calculate_rewards(pos, cfg, clock_obj);
        assert!(reward > 0, 3);
        assert!(balance::value(&cfg.rewards) >= reward, 4);

        pos.reward_accum = 0;
        pos.last_claim = clock::timestamp_ms(clock_obj) / 1000;

        let reward_balance = balance::split(&mut cfg.rewards, reward);
        let reward_coins = coin::from_balance(reward_balance, ctx);
        transfer::public_transfer(reward_coins, tx_context::sender(ctx));
    }

    /// Permite retirar el staking completo con recompensas acumuladas
    public fun unstake(
        pos: StakePosition,
        cfg: &mut Config,
        clock_obj: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(pos.active, 1);
        assert!(pos.owner == tx_context::sender(ctx), 2);

        let now = clock::timestamp_ms(clock_obj) / 1000;
        let days_passed = (now - pos.last_claim) / 86400;
        let reward = (pos.amount * cfg.reward_rate_daily * days_passed) / 10000 + pos.reward_accum;

        if (reward > 0) {
            assert!(balance::value(&cfg.rewards) >= reward, 4);
            let reward_balance = balance::split(&mut cfg.rewards, reward);
            let reward_coins = coin::from_balance(reward_balance, ctx);
            transfer::public_transfer(reward_coins, tx_context::sender(ctx));
        };

        // Destructuring del struct (SIN segundo let)
        let StakePosition {
            id,
            owner,
            amount: _,
            start_time: _,
            reward_accum: _,
            last_claim: _,
            active: _,
            mut coins
        } = pos;

        // Manejo correcto de Option según documentación oficial
        if (option::is_some(&coins)) {
            let c = option::extract(&mut coins);
            transfer::public_transfer(c, owner);
        };
        option::destroy_none(coins);

        object::delete(id);
    }
}
