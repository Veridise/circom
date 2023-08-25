pragma circom 2.0.0;
include "./userStateTransition.circom";
component main = UserStateTransition(
	17, // STATE_TREE_DEPTH,
	17, // EPOCH_TREE_DEPTH,
	17, // HISTORY_TREE_DEPTH,
	2, // EPOCH_KEY_NONCE_PER_EPOCH,
	6, // FIELD_COUNT,
	4, // SUM_FIELD_COUNT,
	48 // REPL_NONCE_BITS
);
