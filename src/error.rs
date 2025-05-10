use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("No participants to draw from")]
    NoParticipants {},

    #[error("No funds sent")]
    NoFunds {},

    #[error("Exceeds max entry amount")]
    ExceedsMaxEntryAmount {},

    #[error("It's too early to execute draw")]
    TooEarly {},    

    #[error("Unauthorized")]
    Unauthorized {},
}
