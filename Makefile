TEMPLATES := $(wildcard *.yaml)
OUT := build
# put output dir in VPATH to simplify finding dependencies
VPATH := $(OUT)

# build output files in the out directory using suffixes (e.g. .lint)
FORMAT = $(addsuffix .format, $(TEMPLATES))
LINT = $(addsuffix .lint, $(TEMPLATES))
VALIDATE = $(addsuffix .validate, $(TEMPLATES))
DEPLOY = $(addsuffix .deploy, $(TEMPLATES))

# delete target if exiting non-zero
.DELETE_ON_ERROR:
.PHONY: all check lint validate clean

all: check

$(OUT):
	mkdir -vp "$(@)"

clean:
	rm -vf $(OUT)/*


check: $(LINT) $(VALIDATE) $(FORMAT) | $(OUT)


$(LINT): %.lint: % | $(OUT)
	cfn-lint --format parseable --info -t $(?) 2>&1 \
	| tee "$(OUT)/$(?).lint"
	@echo

lint: $(LINT) | $(OUT)


$(VALIDATE): %.validate: % | $(OUT)
	aws cloudformation validate-template \
	--template-body	"file://$(?)" 2>&1 \
	| tee "$(OUT)/$(?).validate"
	@echo

validate: $(VALIDATE) | $(OUT)


$(FORMAT): %.format: % | $(OUT)
	cfn-format $(?) 2>&1 > "$(OUT)/$(?).fmt"
	diff $(?) $(OUT)/$(?).fmt 2>&1 | tee $(OUT)/$(?).format 
	@echo

format: $(FORMAT) | $(OUT)


$(DEPLOY): %.deploy: % | $(OUT)
	aws cloudformation deploy \
  --template-file cfn-grafana.yaml \
  --stack-name grafana \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ContainerVpcId="vpc-1" \
    ContainerSubnets="subnet-1,subnet-2,subnet-3" \
    LoadBalancerVpcId="vpc-1" \
    LoadBalancerSubnets="subnet-1,subnet-2,subnet-3" \
  --tags tag1key=tag1value tag2key=tag2value \
  --profile myprofile 2>&1 \
	| tee "$(OUT)/$(?).deploy"

deploy: $(DEPLOY) | $(OUT)

