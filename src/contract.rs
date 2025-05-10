#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{
    to_json_binary, Addr, BankMsg, Coin, Deps, DepsMut, Env, MessageInfo, Response, StdError, StdResult,
    Timestamp, Uint128,
};
use cw2::set_contract_version;
use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg, LotteryStatusResponse};
use crate::state::{Config, CONFIG, LotteryState, LOTTERY_STATE};

const CONTRACT_NAME: &str = "zigchain-lottery";
const CONTRACT_VERSION: &str = "0.1.0";

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> StdResult<Response> {
    let config = Config {
        admin: info.sender.clone(),
        draw_interval: msg.draw_interval,
        max_entry_amount: msg.max_entry_amount,
    };

    CONFIG.save(deps.storage, &config)?;

    let state = LotteryState {
        participants: vec![],
        last_draw: _env.block.time,
    };

    LOTTERY_STATE.save(deps.storage, &state)?;

    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;

    // Ok(Response::default())
    Ok(Response::new().add_attribute("method", "instantiate"))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::EnterLottery {} => execute_enter_lottery(deps, env, info),
        ExecuteMsg::ExecuteDraw {} => execute_draw(deps, env, info),
        ExecuteMsg::WithdrawFees { to_address } => execute_withdraw_fees(deps, env, info, to_address),
    }
}

fn execute_enter_lottery(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    let mut state = LOTTERY_STATE.load(deps.storage)?;

    let sent_amount = info.funds.iter().find(|c| c.denom == "uatom").map(|c| c.amount).unwrap_or(Uint128::zero());
    if sent_amount == Uint128::zero() {
        return Err(ContractError::NoFunds {});
    }

    if sent_amount > config.max_entry_amount {
        return Err(ContractError::ExceedsMaxEntryAmount {});
    }

    state.participants.push(info.sender);
    LOTTERY_STATE.save(deps.storage, &state)?;

    Ok(Response::new().add_attribute("method", "enter_lottery"))
}

fn execute_draw(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    let mut state = LOTTERY_STATE.load(deps.storage)?;

    let now = env.block.time.seconds();
    if now < state.last_draw.seconds() + config.draw_interval {
        return Err(ContractError::TooEarly {});
    }

    let num_players = state.participants.len();
    if num_players == 0 {
        return Err(ContractError::NoParticipants {});
    }

    let balance = deps.querier.query_all_balances(env.contract.address.clone())?;
    let total_pot = balance.iter().find(|c| c.denom == "uatom").map(|c| c.amount).unwrap_or(Uint128::zero());

    let reward_percentage = Uint128::new(99);
    let house_percentage = Uint128::new(1);

    let winner = if num_players == 1 {
        state.participants[0].clone()
    } else {
        let rand_index = (env.block.height % num_players as u64) as usize;
        state.participants[rand_index].clone()
    };

    let winner_reward = total_pot.multiply_ratio(reward_percentage, Uint128::new(100));

    let mut messages = vec![BankMsg::Send {
        to_address: winner.to_string(),
        amount: vec![Coin { denom: "uatom".to_string(), amount: winner_reward }],
    }];

    // Optional: reward caller (can be fixed or %)
    let caller_reward = Uint128::new(5_000); // 0.005 ATOM as example
    if caller_reward < total_pot {
        messages.push(BankMsg::Send {
            to_address: info.sender.to_string(),
            amount: vec![Coin { denom: "uatom".to_string(), amount: caller_reward }],
        });
    }

    state.participants.clear();
    state.last_draw = env.block.time;
    LOTTERY_STATE.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_messages(messages)
        .add_attribute("method", "execute_draw")
        .add_attribute("winner", winner.to_string()))
}

fn execute_withdraw_fees(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    to_address: String,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    if info.sender != config.admin {
        return Err(ContractError::Unauthorized {});
    }

    let balance = deps.querier.query_all_balances(_env.contract.address)?;
    let house_percentage = Uint128::new(1);
    let total_pot = balance.iter().find(|c| c.denom == "uatom").map(|c| c.amount).unwrap_or(Uint128::zero());
    let house_cut = total_pot.multiply_ratio(house_percentage, Uint128::new(100));

    let msg = BankMsg::Send {
        to_address,
        amount: vec![Coin { denom: "uatom".to_string(), amount: house_cut }],
    };

    Ok(Response::new().add_message(msg).add_attribute("method", "withdraw_fees"))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<cosmwasm_std::Binary> {
    // match STATE.load(_deps.storage) {
    //     Ok(state) => to_json_binary(&state.message),
    //     Err(_) => Err(StdError::not_found("state")),
    // }
    match msg {
        QueryMsg::LotteryStatus {} => to_json_binary(&query_lottery_status(deps, env)?),
    }
}

fn query_lottery_status(deps: Deps, env: Env) -> StdResult<LotteryStatusResponse> {
    let state = LOTTERY_STATE.load(deps.storage)?;
    let config = CONFIG.load(deps.storage)?;

    let now = env.block.time.seconds();
    let time_since_last = now - state.last_draw.seconds();
    let can_draw = time_since_last >= config.draw_interval;

    let balance = deps
        .querier
        .query_all_balances(env.contract.address.clone())?
        .iter()
        .find(|c| c.denom == "uatom")
        .cloned()
        .unwrap_or_else(|| Coin { denom: "uatom".to_string(), amount: Uint128::zero() });

    Ok(LotteryStatusResponse {
        can_draw,
        time_remaining: if can_draw { 0 } else { config.draw_interval - time_since_last },
        total_pot: balance,
        num_players: state.participants.len() as u64,
    })
}



//#[cfg(test)]
//mod tests {
//    use super::*;
// 
//    #[test]
//    fn greet_query() {
//        let resp = query::greet().unwrap();
//        assert_eq!(
//            resp,
//            GreetResp {
//                message: "Hello World".to_owned()
//            }
//        );
//    }
//}

#[cfg(test)]
mod tests {
    use super::*;
    use cosmwasm_std::testing::{mock_dependencies, mock_env, mock_info};
    use cosmwasm_std::{attr, coins, Uint128};
    use crate::contract::{instantiate, execute};
    use crate::msg::{InstantiateMsg, ExecuteMsg};

    #[test]
    fn test_instantiate() {
        let mut deps = mock_dependencies();

        let msg = InstantiateMsg {
            draw_interval: 3600,
            max_entry_amount: Uint128::new(1_000_000),
        };
        let info = mock_info("creator", &[]);

        let res = instantiate(deps.as_mut(), mock_env(), info, msg).unwrap();
        assert_eq!(res.attributes, vec![attr("method", "instantiate")]);
    }

    #[test]
    fn test_enter_lottery() {
        let mut deps = mock_dependencies();

        let msg = InstantiateMsg {
            draw_interval: 3600,
            max_entry_amount: Uint128::new(1_000_000),
        };
        let info = mock_info("creator", &[]);
        instantiate(deps.as_mut(), mock_env(), info, msg).unwrap();

        let info = mock_info("player1", &coins(500_000, "uatom"));
        let res = execute(deps.as_mut(), mock_env(), info, ExecuteMsg::EnterLottery {}).unwrap();
        assert_eq!(res.attributes, vec![attr("method", "enter_lottery")]);
    }

    #[test]
    fn test_execute_draw_too_early() {
        let mut deps = mock_dependencies();

        let msg = InstantiateMsg {
            draw_interval: 3600,
            max_entry_amount: Uint128::new(1_000_000),
        };
        let info = mock_info("creator", &[]);
        instantiate(deps.as_mut(), mock_env(), info, msg).unwrap();

        let info = mock_info("caller", &[]);
        let res = execute(deps.as_mut(), mock_env(), info, ExecuteMsg::ExecuteDraw {});
        assert!(res.is_err());
    }
}
