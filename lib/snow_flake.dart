class SnowFlake {
  /// 开始时间截 (2020-01-01)
  final int twepoch = 1577808000000;

  /// 机器id所占的位数
  static const int workerIdBits = 5;

  /// 数据标识id所占的位数
  static const int datacenterIdBits = 5;

  /// 支持的最大机器id，结果是31 (这个移位算法可以很快的计算出几位二进制数所能表示的最大十进制数)
  final int maxWorkerId = -1 ^ (-1 << workerIdBits);

  /// 支持的最大数据标识id，结果是31
  final int maxDatacenterId = -1 ^ (-1 << datacenterIdBits);

  /// 序列在id中占的位数
  static const int sequenceBits = 12;

  /// 机器ID向左移12位
  final int workerIdShift = sequenceBits;

  /// 数据标识id向左移17位(12+5)
  final int datacenterIdShift = sequenceBits + workerIdBits;

  /// 时间截向左移22位(5+5+12)
  final int timestampLeftShift = sequenceBits + workerIdBits + datacenterIdBits;

  /// 生成序列的掩码，这里为4095 (0b111111111111=0xfff=4095)
  final int sequenceMask = -1 ^ (-1 << sequenceBits);

  /// 工作机器ID(0~31)
  int workerId;

  /// 数据中心ID(0~31)
  int datacenterId;

  /// 毫秒内序列(0~4095)
  int sequence = 0;

  /// 上次生成ID的时间截
  int lastTimestamp = -1;

  //==============================Constructors=====================================
  /// 构造函数
  /// @param workerId 工作ID (0~31)
  /// @param datacenterId 数据中心ID (0~31)
  SnowFlake(this.workerId, this.datacenterId) {
    if (workerId > maxWorkerId || workerId < 0) {
      // throw Exception("worker Id can't be greater than $maxWorkerId or less than 0");
    }
    if (datacenterId > maxDatacenterId || datacenterId < 0) {
      // throw Exception("datacenter Id can't be greater than $maxDatacenterId or less than 0");
    }
  }

  factory SnowFlake.factory({int workerId = 1, int datacenterId = 0}) {
    return SnowFlake(workerId, datacenterId);
  }

  // ==============================Methods==========================================
  /// 获得下一个ID (该方法是线程安全的)
  /// @return SnowflakeId
  int nextId() {
    int timestamp = _timeGen();

    // 如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
    if (timestamp < lastTimestamp) {
      // throw Exception("Clock moved backwards.  Refusing to generate id for ${lastTimestamp - timestamp} milliseconds");
      return timestamp;
    }

    // 如果是同一时间生成的，则进行毫秒内序列
    if (lastTimestamp == timestamp) {
      sequence = (sequence + 1) & sequenceMask;
      // 毫秒内序列溢出
      if (sequence == 0) {
        // 阻塞到下一个毫秒,获得新的时间戳
        timestamp = _tilNextMillis(lastTimestamp);
      }
    }
    // 时间戳改变，毫秒内序列重置
    else {
      sequence = 0;
    }

    // 上次生成ID的时间截
    lastTimestamp = timestamp;

    // 移位并通过或运算拼到一起组成64位的ID
    return ((timestamp - twepoch) << timestampLeftShift) //
    | (datacenterId << datacenterIdShift) //
    | (workerId << workerIdShift) //
    | sequence;
  }

  /// 阻塞到下一个毫秒，直到获得新的时间戳
  /// @param lastTimestamp 上次生成ID的时间截
  /// @return 当前时间戳
  int _tilNextMillis(int lastTimestamp) {
    int timestamp = _timeGen();
    while (timestamp <= lastTimestamp) {
      timestamp = _timeGen();
    }
    return timestamp;
  }

  /// 返回以毫秒为单位的当前时间
  /// @return 当前时间(毫秒)
  int _timeGen() => DateTime.now().millisecondsSinceEpoch;
}
