# The 7 "hearth" scenes behind the flame on the profile hero and the Focus
# screen: a fixed set of layered shapes (an ember bed, logs, stones, flying
# sparks, a twinkling star, and — top tier only — a lighthouse beam) that
# grow more elaborate as the tier rises, rather than a single flame scaling
# continuously. Ported from the "1a — le feu se construit" direction in the
# Claude Design project "Modernisation planner utilisateur" (`HEARTH` in
# Move the Spark.dc.html, explored in Paliers du foyer.dc.html).
#
# Tier 4 is named "Ardeur" throughout this app, not "Flamme" (the source
# design's name for that tier) — a deliberate rename to avoid confusion with
# "flamme" already meaning the daily/weekly streak elsewhere in the UI. Keep
# it that way; see ApplicationHelper::LEVEL_TIERS.
class HearthScene
  # :x/:b are a percentage-from-left / pixels-from-bottom position for
  # :flame, :halo, :bed, :coal, :log (centered shapes read only :b) — except
  # for :stone and :spark, where :x is a pixel offset from the horizontal
  # center instead (matches the source design's own two different units).
  Layer = Struct.new(
    :type, :x, :b, :w, :h, :size, :rot, :delay, :color, :opacity, :variant, :duration,
    keyword_init: true
  )

  TIER_RANGE = 1..7

  def self.for_tier(tier)
    new(tier)
  end

  def initialize(tier)
    @tier = tier.to_i.clamp(TIER_RANGE)
  end

  def layers
    SCENES.fetch(@tier)
  end

  # ── Layer builders — internal only, mirror the shape/animation each type
  #    renders as; see shared/_hearth_scene.html.erb for the actual markup.

  def self.flame(x, b, size, delay = 0)
    Layer.new(type: :flame, x: x, b: b, size: size, delay: delay)
  end

  def self.halo(b, size, color, opacity)
    Layer.new(type: :halo, b: b, size: size, color: color, opacity: opacity)
  end

  def self.bed(b, w, h)
    Layer.new(type: :bed, b: b, w: w, h: h)
  end

  def self.coal(x, b, size, delay)
    Layer.new(type: :coal, x: x, b: b, size: size, delay: delay)
  end

  def self.coals(b)
    [ coal(45, b, 8, 0), coal(50, b + 2, 10, 0.6), coal(55, b, 7, 1.1) ]
  end

  def self.log(b, w, rot)
    Layer.new(type: :log, b: b, w: w, rot: rot)
  end

  def self.stone(dx, w, h)
    Layer.new(type: :stone, x: dx, w: w, h: h)
  end

  def self.spark(dx, b, variant, duration, delay, color)
    Layer.new(type: :spark, x: dx, b: b, variant: variant, duration: duration, delay: delay, color: color)
  end

  SPARK_PRESET = [
    [ -8, "a", 3.2, 0 ], [ 8, "b", 3.8, 1.1 ], [ 0, "c", 3.4, 2 ],
    [ -17, "b", 4, 0.5 ], [ 17, "a", 3.6, 1.6 ], [ -4, "c", 4.2, 2.6 ]
  ].freeze

  def self.sparks(b, n)
    SPARK_PRESET.first(n).map.with_index do |(dx, variant, duration, delay), i|
      spark(dx, b, variant, duration, delay, i % 3 == 1 ? "oklch(0.9 0.12 86)" : "#E2652C")
    end
  end

  def self.star(b, size)
    Layer.new(type: :star, b: b, size: size)
  end

  def self.beam
    Layer.new(type: :beam)
  end

  def self.tower
    Layer.new(type: :tower)
  end

  private_class_method :flame, :halo, :bed, :coal, :coals, :log, :stone, :spark, :sparks, :star, :beam, :tower

  SCENES = {
    1 => [
      halo(-10, 120, "oklch(0.62 0.18 40 / .55)", 0.5), bed(6, 92, 28),
      coal(43, 12, 8, 0), coal(50, 15, 11, 0.6), coal(57, 11, 8, 1.1), coal(46, 8, 7, 0.3), coal(54, 7, 7, 0.9)
    ],
    2 => [
      halo(10, 120, "oklch(0.7 0.18 55 / .55)", 0.6), bed(6, 80, 24), *coals(11),
      halo(36, 56, "oklch(0.85 0.14 75 / .8)", 0.9), star(48, 26),
      spark(0, 50, "c", 3.4, 0.8, "oklch(0.9 0.12 86)")
    ],
    3 => [
      halo(-6, 140, "oklch(0.66 0.19 46 / .55)", 0.65), bed(6, 84, 24), *coals(11),
      flame(50, 13, 44), *sparks(44, 2)
    ],
    4 => [
      halo(-12, 170, "oklch(0.66 0.19 46 / .55)", 0.75), log(9, 76, 13), log(9, 76, -13), *coals(15),
      flame(50, 17, 64), *sparks(60, 3)
    ],
    5 => [
      halo(-12, 180, "oklch(0.66 0.19 46 / .55)", 0.8), log(13, 72, 13), log(13, 72, -13),
      flame(50, 20, 72),
      stone(-36, 20, 13), stone(-18, 18, 11), stone(0, 21, 12), stone(18, 18, 11), stone(36, 20, 13),
      *sparks(70, 3)
    ],
    6 => [
      halo(-20, 220, "oklch(0.68 0.19 48 / .6)", 0.95), log(7, 92, 0), log(14, 80, 14), log(14, 80, -14),
      flame(34, 20, 50, 0.4), flame(66, 20, 54, 0.9), flame(50, 21, 88),
      *sparks(80, 6)
    ],
    7 => [
      beam, halo(40, 130, "oklch(0.75 0.17 60 / .6)", 0.85), tower,
      flame(50, 62, 42), *sparks(84, 3)
    ]
  }.freeze
end
