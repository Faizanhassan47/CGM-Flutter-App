/// Link power-saving switch: Should we proactively request connection parameters?。
///
/// For transmitter CR1025（30 mAh），15 The entire system budget for Tiandai period is only 83 µA，Link idling is the largest single item。
/// Android central Connection parameter updates can be sent directly, and you can choose between ”our initiative request” and ”let the firmware negotiate”。
///
/// Firmware connection is about 2 It will be sent automatically in seconds L2CAP Connection Parameter Update Request，want
/// `interval 1000ms / latency 0 / timeout 6000ms`（Link approx. 7.3 µA，enough 17 sky）；
/// ours `lowPower(100-125ms + latency 2)` Effective wake-up is only 360 ms，Worse than firmware 3 times，
/// Will be posted later 1000ms Cover it and wear the whole section 14.6 sky. The device is designed according to ”firmware has the final say”。
///
/// - false（Default): No priority requests are sent (upgrade high It won’t be sent that way), the firmware will run whatever it negotiates.。
/// - true：Steady state active request lowPower。Only open if the firmware does not negotiate
///   （HCI There is no firmware in it L2CAP Request, link stops at 45ms）。
///
/// It won’t work if you only block downshifts but not upshifts: make up for the upshifts. high(11.25-15ms) Can’t come back anymore，3-4 The whole day is exhausted。
class BleLinkTuning {
  const BleLinkTuning._();

  static bool ownStableInterval = false;
}
