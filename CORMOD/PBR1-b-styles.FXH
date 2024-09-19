//常用常量，与确定的风格参数===================
//并非所有都有用

static const float PIE = radians(180) ; //圆周率
static const bool  base_texture_gamma = true ; //是否对主贴图进行gamma修正
static const bool  double_hc_bright = true ; //像原版一样翻倍阵营色亮度
static const bool  exchange_tangent_in3dsmax = false ; //对MAX预览互换切线，因为似乎是反的

static const float FresnelF0 =  0.125 ; //绝缘体菲涅尔效应F0，即反射角为0时高光亮度
static const float FresnelMetalF0 = 0.875 ; //金属的菲涅尔F0
static const float reflectivity_cutoff = 0.5 ; //SPM红色多长一段用来记录非金属反光度
static const float MinRoughness = 1/16 ; //最低粗糙度，防止除以零或者log变负数

static const float max_skybox_lod_bias = 16 ; //最大粗糙度时使用的天空盒mipmap偏移（8会被log到3）
static const bool  skybox_lod_absolute = false ; //用绝对lod而非相对lod bias采样模糊天空盒
static const bool  skybox_lod_logarithmic = true ; //是否根据粗糙度的log2修正天空盒mipmap偏移
static const 

static const float ambient_diff_multiply =  0.75 ; //环境光与天空盒diffuse
static const float ambient_spec_multiply =  0.75 ; //环境光与天空盒specular
static const float ambient_SKY_multiply =  1 ; //拟合天空盒的天空色亮度
static const float ambient_GROUND_multiply =  0.75 ; //拟合天空盒的地面色亮度
static const float pointlight_multiply =  1 ; //点光源整体亮度
static const float sunlight_multiply =  1 ; //阳光亮度
static const float diffuse_multiply =  1 ; //漫反射亮度，影响阳光与点光源
static const float specbase_multiply =  1 ; //高光在最大粗糙度金属下的基础峰值亮度，影响阳光与点光源

static const float shadowBias =  1/256 ; //阴影偏移，防止给自己投影
// static const int   ShadowPCFlevel = 2 ; //柔和阴影的十字采样数量是这个乘4
static const bool  HasCloud = false ; //允许动态云影响阳光亮度
static const bool  HasWarfog = false ; //允许接受战争迷雾（大多数单位直接会消失所以没必要）


/*
static const int   calculate_diffuse_type = 2 ; //是否直射光漫反射要被菲涅尔修正，及其精确度
static const bool  difcolor_F0_loss = true ; //对垂直入射光线依然分走能量（如果已经烘焙到base图或F0极小就关闭）
static const float ambient_reflectivity_loss =  0.4 ; //环境光被菲涅尔效应分走的能量比例（算下半球体积分?）
static const float direct_reflectivity_loss =  0.75 ; //直射光被菲涅尔效应分走的能量比例（type2）
static const float direct_fresnel_cutoff =  1.75 ; //拟合上面那个用的，1-2之间越小越显著（type1）

*/