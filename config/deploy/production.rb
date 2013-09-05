# aws-sdk local実行時は動いたら困るので、production時のみ使う
AWS.config({
	:ec2_endpoint => 'ec2.ap-northeast-1.amazonaws.com',
	:elb_endpoint => 'elasticloadbalancing.ap-northeast-1.amazonaws.com'
})

# 対象のautoscaling_group上のec2_instanceに対してdeploy
autoscaling_group = AWS::AutoScaling.new.groups["#{autoscaling_group_name}"]
instances = autoscaling_group.ec2_instances.select {|i| i.exists? && i.status == :running}.map(&:dns_name)

# localhostもデプロイ対象に追加
instances.push("localhost")

role :web, *instances
set :branch, fetch(:branch, "master")

