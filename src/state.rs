use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Timestamp, Uint128};
use cw_storage_plus::Item;

#[cw_serde]
pub struct Config {
    pub admin: Addr,
    pub draw_interval: u64, // in seconds
    pub max_entry_amount: Uint128,
}

#[cw_serde]
pub struct LotteryState {
    pub participants: Vec<Addr>,
    pub last_draw: Timestamp,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const LOTTERY_STATE: Item<LotteryState> = Item::new("lottery_state");
