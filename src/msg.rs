use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Coin, Uint128};

#[cw_serde]
pub struct InstantiateMsg {
    pub draw_interval: u64,
    pub max_entry_amount: Uint128,
}

#[cw_serde]
pub enum ExecuteMsg {
    EnterLottery {},
    ExecuteDraw {},
    WithdrawFees { to_address: String },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(LotteryStatusResponse)]
    LotteryStatus {},
}

#[cw_serde]
pub struct LotteryStatusResponse {
    pub can_draw: bool,
    pub time_remaining: u64,
    pub total_pot: Coin,
    pub num_players: u64,
}