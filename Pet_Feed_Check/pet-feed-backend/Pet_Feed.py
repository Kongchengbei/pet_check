from Paddle_OCR import imgmd_OCR
from Text_Check import judge
import re
import time
from config import LLM_TOKEN, OCR_TOKEN

def filter_compliance_output(model_output, level):
    text = re.sub(r'^.*think>', '', model_output, flags=re.DOTALL)
    text = re.sub(
        r'(?m)^\s*(?:#{1,6}\s*)?\*{0,2}【([^】]+)】\*{0,2}\s*$',
        r'【\1】',
        text
    )
    fields = [
        ("执法提示", [
            "执法提示",
            "执法建议",
            "监管建议",
            "监管提示",
            "整改建议",
            "整改意见",
            "处理建议",
            "处置建议",
            "执法意见",
            "监管意见",
            "建议措施",
            "后续建议",
            "处理意见",
            "审查建议",
            "合规建议",
        ]),
        ("法条依据", [
            "法条依据",
            "法律依据",
            "法规依据",
            "法律条款",
            "法规条款",
            "相关法条",
            "相关法规",
            "相关法律",
            "援引法条",
            "引用法条",
            "条款依据",
            "依据条款",
            "法律引用",
            "适用法规",
            "适用法条",
            "依据法规",
            "依据法律",
            "参考法规",
            "参考法条",
        ]),
        ("违规点", [
            "违规点",
            "违规项",
            "违规内容",
            "违规事项",
            "违规问题",
            "违规情况",
            "不合规点",
            "不合规项",
            "不合规内容",
            "不合规事项",
            "违法点",
            "违法项",
            "问题点",
            "问题项",
            "问题内容",
            "存在问题",
            "主要问题",
            "发现问题",
            "审查问题",
            "瑕疵点",
            "缺陷项",
        ]),
        ("合规判定", [
            "合规判定",
            "合规判断",
            "合规结果",
            "判定结果",
            "判断结果",
            "审查结果",
            "审查结论",
            "合规结论",
            "合规性判定",
            "合规性判断",
            "合规性结论",
            "总体判定",
            "总体结论",
            "综合判定",
            "综合结论",
            "最终判定",
            "最终结论",
            "结论",
            "判定",
        ]),
    ]
    extracted = {}
    remaining_text = text
    for field_name, aliases in fields:
        last_pos = -1
        matched_alias = None
        for alias in aliases:
            marker = f"【{alias}】"
            pos = remaining_text.rfind(marker)
            if pos > last_pos:
                last_pos = pos
                matched_alias = alias
        if last_pos != -1:
            marker = f"【{matched_alias}】"
            content = remaining_text[last_pos + len(marker):].strip()
            extracted[field_name] = content
            remaining_text = remaining_text[:last_pos]
    result = []
    if level >= 1 and extracted.get("合规判定"):
        result.append(f"**【合规判定】**\n{extracted['合规判定']}")
    if level >= 2 and extracted.get("违规点"):
        result.append(f"**【违规点】**\n{extracted['违规点']}")
    if level >= 3:
        if extracted.get("法条依据"):
            result.append(f"**【法条依据】**\n{extracted['法条依据']}")
        if extracted.get("执法提示"):
            result.append(f"**【执法提示】**\n{extracted['执法提示']}")
    return "\n\n".join(result)

def run_audit(image_path, model, DEBUG=False, level=1):
    try:
        start_time = time.time()
        if not OCR_TOKEN:
            return "❌ OCR_TOKEN 未配置，请在微信云托管或本地环境变量中设置"
        if not LLM_TOKEN:
            return "❌ LLM_TOKEN 未配置，请在微信云托管或本地环境变量中设置"
        try:
            ocr_text = imgmd_OCR(image_path, OCR_TOKEN)
        except Exception as e:
            return f"❌ OCR失败：{str(e)}"
        try:
            llm_result = judge(ocr_text, LLM_TOKEN, model, DEBUG)
        except Exception as e:
            return f"❌ LLM调用失败：{str(e)}"
        try:
            audit_result = filter_compliance_output(llm_result, level)
            if audit_result == "":
                return re.sub(r'^.*think>', '', llm_result, flags=re.DOTALL)
        except Exception as e:
            return f"❌ 结果处理失败：{str(e)}"
        end_time = time.time()
        if DEBUG:
            print(f"【审核耗时】\n{end_time - start_time:.2f} 秒")
            print("【输入图片路径】\n" + image_path)
            print("【使用模型】\n" + model)
            print("【审核等级】\n" + str(level))
            print("【OCR识别内容】\n" + ocr_text)
            print("【LLM原始输出】\n" + llm_result)
            print("【最终审核结果】\n" + audit_result)

        return audit_result

    except Exception as e:
        return f"❌ 审核失败：{str(e)}"

if __name__ == "__main__":
    image_path = r"D:\code_project\Pet_Feed_Check\demo\Utils\demo\test.jpg"
    model = "DeepSeek-R1"
    level = 3
    DEBUG = True
    audit_result = run_audit(image_path, model, DEBUG,level)


