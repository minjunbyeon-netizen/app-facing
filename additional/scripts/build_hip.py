import json

def danger_hip():
    return {
        "title": "지금 바로 운동을 멈추세요",
        "reason": "안정 시에도 사타구니·고관절 통증이 지속되거나 다리로 저림이 있으면 관절 손상·탈구 등 구조적 문제가 의심됩니다.",
        "action": "정형외과 또는 스포츠의학과 진료를 권장합니다. 통증 위치와 발생 동작을 기록해 방문하세요."
    }

def cause_fai(return_exercise):
    return {
        "id": "cause-a", "label": "원인 A", "tag": "가동성 부족",
        "name": "고관절 임핀지먼트 (FAI) — 사타구니 찝힘",
        "description": "고관절을 깊이 구부릴 때 대퇴골두와 비구 테두리가 충돌하면서 사타구니 안쪽이 찝힙니다. 고관절 굴곡 가동성과 내회전 가동성을 확보하면 충돌 없이 동작이 가능해집니다.",
        "priority_note": "고관절 가동성 확보가 먼저, 부하는 그 다음입니다.",
        "route": {
            "stages": [
                {
                    "id": "stage-1", "name": "이완", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "90/90 힙 스트레칭",
                            "why": "고관절 내회전·외회전 가동성을 동시에 풀어줍니다. 임핀지먼트는 내회전이 제한될 때 더 심해집니다.",
                            "sets": "좌우 각 60초 · 3세트",
                            "cue": "억지로 누르지 말고 중력에 맡겨 천천히 이완합니다.",
                            "how": [
                                "바닥에 앉아 앞 다리와 뒤 다리를 각각 90도로 구부리세요",
                                "상체를 앞 다리 정강이 쪽으로 부드럽게 숙이세요",
                                "60초 유지 후 반대쪽"
                            ]
                        },
                        {
                            "name": "피겨4 스트레칭",
                            "why": "이상근과 고관절 외회전근을 이완해 고관절 안쪽 공간을 확보합니다.",
                            "sets": "좌우 각 60초 · 2세트",
                            "cue": "엉덩이 바깥쪽이 당기는 느낌이 나야 합니다.",
                            "how": [
                                "바닥에 누워 한쪽 발목을 반대쪽 무릎 위에 올리세요",
                                "세운 무릎을 가슴 쪽으로 당기면 엉덩이 바깥쪽이 당깁니다",
                                "60초 유지 후 반대쪽"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-2", "name": "가동성", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "개구리 자세 (Frog Stretch)",
                            "why": "고관절 내회전·굴곡 가동성을 동시에 개선합니다. 임핀지먼트가 있는 각도를 통증 없는 범위에서 점진적으로 열어줍니다.",
                            "sets": "30~60초 유지 · 3세트",
                            "cue": "엉덩이를 뒤로 빼며 허벅지 안쪽이 당기는 느낌을 찾으세요.",
                            "how": [
                                "네 발 자세에서 무릎을 양옆으로 최대한 벌리세요",
                                "엉덩이를 천천히 뒤로 빼며 고관절이 열리는 느낌을 찾으세요",
                                "30~60초 유지 · 3세트"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-3", "name": "활성화", "duration": "1주",
                    "exercises": [
                        {
                            "name": "클램쉘 + 사이드라잉 힙 어브덕션",
                            "why": "고관절 외전근을 강화하면 임핀지먼트 없이 안정적으로 고관절을 사용할 수 있습니다.",
                            "sets": "좌우 각 15회 · 3세트",
                            "cue": "발뒤꿈치를 붙인 채 위 무릎만 벌립니다.",
                            "how": [
                                "클램쉘 15회 → 사이드라잉 어브덕션 15회 순으로",
                                "좌우 각 3세트"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-4", "name": "패턴", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "맨몸 동작 (얕은 범위)",
                            "why": "가동성 개선 후 통증 없는 범위에서 실제 동작 패턴을 연습합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "찝힘이 시작되는 각도 직전까지만 내려갑니다.",
                            "how": [
                                "맨몸으로 동작을 수행하며 사타구니 찝힘 없는 깊이를 확인하세요",
                                "가동성이 늘수록 점진적으로 깊이를 늘리세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-5", "name": "볼륨", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "경부하 동작",
                            "why": "가동성이 충분히 확보되면 부하를 추가합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "사타구니 찝힘 없이 수행 가능한 무게만 사용합니다.",
                            "how": [
                                "가벼운 무게로 시작해 찝힘 없이 3세트 완료 시 무게를 올리세요",
                                "매 훈련 전 90/90 스트레칭을 워밍업으로 수행하세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-6", "name": "복귀", "duration": "지속",
                    "exercises": [return_exercise]
                }
            ]
        }
    }

def cause_hip_flexor(return_exercise):
    return {
        "id": "cause-b", "label": "원인 B", "tag": "과긴장",
        "name": "고관절 굴곡근 긴장 (앞쪽 통증)",
        "description": "장요근·대퇴직근이 과도하게 긴장되면 동작 중 고관절 앞쪽이 당기거나 쑤십니다. 오래 앉아있거나 훈련 볼륨이 급격히 늘었을 때 흔합니다. 이완과 함께 고관절 신전 근력을 키워야 재발을 막을 수 있습니다.",
        "priority_note": "이완 먼저, 고관절 신전 강화는 그 다음입니다.",
        "route": {
            "stages": [
                {
                    "id": "stage-1", "name": "이완", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "로우 런지 스트레칭 (Couch Stretch)",
                            "why": "장요근을 직접 이완합니다. 동작 중 고관절 앞쪽 통증의 가장 직접적인 원인 근육입니다.",
                            "sets": "좌우 각 60초 · 3세트",
                            "cue": "골반을 앞으로 밀면서 허리는 곧게 유지합니다.",
                            "how": [
                                "한 발을 앞에, 반대 무릎을 바닥에 놓는 런지 자세를 취하세요",
                                "뒷발 쪽 엉덩이를 앞으로 밀면서 고관절 앞쪽이 당기는 느낌을 찾으세요",
                                "60초 유지 후 반대쪽"
                            ]
                        },
                        {
                            "name": "폼롤러 고관절 굴곡근 이완",
                            "why": "대퇴직근과 장요근 근막을 직접 이완합니다.",
                            "sets": "좌우 각 60초 · 2세트",
                            "cue": "가장 아픈 지점에서 멈추고 숨을 내쉬며 이완하세요.",
                            "how": [
                                "엎드려 폼롤러를 허벅지 앞쪽(사타구니 아래)에 대세요",
                                "천천히 굴리며 가장 아픈 지점에서 30초 멈추세요",
                                "좌우 각 60초"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-2", "name": "활성화", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "글루트 브릿지",
                            "why": "대둔근을 강화하면 고관절 신전력이 생겨 굴곡근의 과부하를 줄입니다.",
                            "sets": "15회 · 3세트",
                            "cue": "최고점에서 엉덩이를 2초 쥐어짜세요.",
                            "how": [
                                "바닥에 누워 무릎을 세우세요",
                                "엉덩이를 들어 무릎·골반·어깨가 일직선이 되게 하세요",
                                "2초 유지 후 천천히 내립니다 · 15회 · 3세트"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-3", "name": "패턴", "duration": "1주",
                    "exercises": [
                        {
                            "name": "맨몸 동작 (이완 후)",
                            "why": "이완 후 실제 동작에서 고관절 앞쪽 통증이 줄었는지 확인합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "동작 전 코치 스트레칭을 항상 수행하세요.",
                            "how": [
                                "이완 직후 맨몸 동작을 수행하며 통증 여부를 확인하세요",
                                "통증 없으면 세트를 늘리세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-4", "name": "경부하", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "경부하 동작",
                            "why": "이완이 유지되면 부하를 추가합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "고관절 앞쪽 통증 0~1/10에서만 진행합니다.",
                            "how": [
                                "가벼운 무게로 시작해 통증 없이 완료 시 무게를 올리세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-5", "name": "볼륨", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "점진적 부하",
                            "why": "이완 루틴을 유지하며 무게를 올려 복귀합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "매 훈련 전 코치 스트레칭은 영구적으로 유지하세요.",
                            "how": [
                                "매 세션 무게를 조금씩 올리며 고관절 앞쪽 반응을 확인하세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-6", "name": "복귀", "duration": "지속",
                    "exercises": [return_exercise]
                }
            ]
        }
    }

def cause_glute(return_exercise):
    return {
        "id": "cause-c", "label": "원인 C", "tag": "근력 부족",
        "name": "중둔근·이상근 긴장 (바깥쪽·엉덩이 통증)",
        "description": "중둔근이 약하거나 이상근이 긴장되면 고관절 바깥쪽 또는 엉덩이에 통증이 생깁니다. 특히 한 발에 체중이 실릴 때 심해집니다. 이완과 함께 중둔근을 강화해야 합니다.",
        "priority_note": "이완 먼저, 중둔근 강화는 그 다음입니다.",
        "route": {
            "stages": [
                {
                    "id": "stage-1", "name": "이완", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "피겨4 스트레칭",
                            "why": "이상근과 고관절 외회전근을 이완합니다.",
                            "sets": "좌우 각 60초 · 3세트",
                            "cue": "엉덩이 바깥쪽이 당기는 느낌이 나야 합니다.",
                            "how": [
                                "바닥에 누워 한쪽 발목을 반대쪽 무릎 위에 올리세요",
                                "세운 무릎을 가슴 쪽으로 당기면 엉덩이 바깥쪽이 당깁니다",
                                "60초 유지 후 반대쪽"
                            ]
                        },
                        {
                            "name": "폼롤러 중둔근·이상근 이완",
                            "why": "엉덩이 측면·뒤쪽 근막 긴장을 직접 풀어줍니다.",
                            "sets": "좌우 각 60초 · 2세트",
                            "cue": "가장 아픈 지점에서 멈추고 발목을 교차해 압박을 높이세요.",
                            "how": [
                                "바닥에 앉아 폼롤러를 한쪽 엉덩이 아래에 대세요",
                                "아픈 쪽 발을 반대쪽 무릎 위에 올려 압박을 높이세요",
                                "60초 굴리며 아픈 지점에서 30초 멈추세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-2", "name": "활성화", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "클램쉘",
                            "why": "중둔근을 무릎·허리 부하 없이 직접 자극합니다.",
                            "sets": "좌우 각 15회 · 3세트",
                            "cue": "발뒤꿈치끼리 붙인 채 위쪽 무릎만 벌립니다.",
                            "how": [
                                "옆으로 누워 무릎을 45도 구부리세요",
                                "발뒤꿈치를 붙인 채 위쪽 무릎을 천장 방향으로 벌리세요",
                                "15회 후 반대쪽 · 3세트"
                            ]
                        },
                        {
                            "name": "밴드 사이드 워크",
                            "why": "서서 이동하며 중둔근을 기능적으로 강화합니다.",
                            "sets": "좌우 각 15보 · 3세트",
                            "cue": "무릎이 발끝 방향을 유지하고 상체는 흔들리지 않도록 합니다.",
                            "how": [
                                "저항 밴드를 무릎 바로 위에 걸고 어깨너비로 서세요",
                                "살짝 스쿼트 자세를 유지하며 옆으로 15보 이동하세요",
                                "반대 방향도 15보"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-3", "name": "패턴", "duration": "1주",
                    "exercises": [
                        {
                            "name": "맨몸 동작 (이완 후)",
                            "why": "이완과 활성화 후 실제 동작에서 엉덩이 통증이 줄었는지 확인합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "동작 전 피겨4 스트레칭을 항상 수행하세요.",
                            "how": [
                                "이완 직후 맨몸 동작을 수행하며 통증 여부를 확인하세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-4", "name": "경부하", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "경부하 동작",
                            "why": "이완이 유지되면 부하를 추가합니다.",
                            "sets": "10회 · 3세트",
                            "cue": "고관절 바깥쪽 통증 0~1/10에서만 진행합니다.",
                            "how": ["가벼운 무게로 시작해 통증 없이 완료 시 무게를 올리세요"]
                        }
                    ]
                },
                {
                    "id": "stage-5", "name": "볼륨", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "점진적 부하",
                            "why": "중둔근이 강해지면 통증 없이 더 큰 부하를 소화할 수 있습니다.",
                            "sets": "10회 · 3세트",
                            "cue": "이완 루틴을 항상 워밍업으로 유지하세요.",
                            "how": ["매 세션 무게를 조금씩 올리며 고관절 바깥쪽 반응을 확인하세요"]
                        }
                    ]
                },
                {
                    "id": "stage-6", "name": "복귀", "duration": "지속",
                    "exercises": [return_exercise]
                }
            ]
        }
    }

def cause_hamstring_proximal(return_exercise):
    return {
        "id": "cause-a", "label": "원인 A", "tag": "과부하",
        "name": "햄스트링 부착부 건병증 (좌골결절 통증)",
        "description": "데드리프트 셋업 시 고관절을 깊이 굽히면 햄스트링이 최대로 늘어납니다. 반복 부하가 쌓이면 햄스트링이 좌골결절(앉으면 닿는 뼈 아래)에 붙는 지점에 건병증이 생깁니다. 앉거나 고관절을 구부릴 때 아픈 것이 특징입니다.",
        "priority_note": "편심성(늘어나는) 강화가 핵심입니다. 스트레칭은 초기에 피하세요.",
        "route": {
            "stages": [
                {
                    "id": "stage-1", "name": "이완", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "폼롤러 햄스트링 이완 (부착부 제외)",
                            "why": "부착부(좌골결절)는 직접 압박하지 않고, 햄스트링 중간·하부를 이완해 전체 장력을 줄입니다.",
                            "sets": "60~90초 · 2세트",
                            "cue": "엉덩이 바로 아래는 피하고 허벅지 중간부터 무릎 위까지만 굴리세요.",
                            "how": [
                                "의자나 박스 위에 앉아 폼롤러를 허벅지 뒤쪽에 대세요",
                                "엉덩이 아래(좌골결절)는 피하고 중간부터 무릎 위까지 굴리세요",
                                "좌우 각 60~90초"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-2", "name": "활성화", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "등척성 햄스트링 홀드",
                            "why": "건병증 초기에는 등척성 수축이 통증을 줄이면서 건을 자극합니다.",
                            "sets": "45초 유지 · 4세트",
                            "cue": "통증 3/10 이하에서 수행합니다.",
                            "how": [
                                "누워서 무릎을 30~45도 구부리세요",
                                "뒤꿈치로 바닥을 밀며 햄스트링을 수축해 45초 유지하세요",
                                "4세트"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-3", "name": "편심성", "duration": "2~3주",
                    "exercises": [
                        {
                            "name": "노르딕 햄스트링 컬 (소범위)",
                            "why": "편심성 강화가 햄스트링 건병증 재활의 핵심입니다. 천천히 내려오는 동작에서 건이 강화됩니다.",
                            "sets": "6~8회 · 3세트",
                            "cue": "통증이 생기는 범위 직전에서 멈춥니다. 범위를 점진적으로 늘립니다.",
                            "how": [
                                "파트너가 발목을 잡거나 바에 발목을 고정하세요",
                                "천천히 앞으로 넘어지며 5초에 걸쳐 내려오세요",
                                "손으로 바닥을 짚어 올라오세요 · 6~8회 · 3세트"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-4", "name": "경부하", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "RDL (경부하)",
                            "why": "편심성 강화가 충분히 되면 RDL로 실제 데드리프트 패턴에 통합합니다.",
                            "sets": "8회 · 3세트",
                            "cue": "좌골결절 통증 0~1/10에서만 진행합니다.",
                            "how": [
                                "가벼운 무게로 RDL을 수행하며 좌골결절 통증을 확인하세요",
                                "통증 없으면 무게를 올리세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-5", "name": "볼륨", "duration": "1~2주",
                    "exercises": [
                        {
                            "name": "데드리프트 점진적 복귀",
                            "why": "RDL에서 통증이 없으면 풀 데드리프트로 복귀합니다.",
                            "sets": "5회 · 4세트",
                            "cue": "다음날 좌골결절 통증이 없어야 무게를 올립니다.",
                            "how": [
                                "1RM 50%로 시작해 좌골결절 통증 여부를 확인하세요",
                                "다음날 통증 없으면 5~10kg씩 올리세요"
                            ]
                        }
                    ]
                },
                {
                    "id": "stage-6", "name": "복귀", "duration": "지속",
                    "exercises": [return_exercise]
                }
            ]
        }
    }

# ── 복귀 운동 ────────────────────────────────────────────────────
squat_return = {
    "name": "스쿼트 전 구간 복귀",
    "why": "고관절 통증이 없으면 훈련 복귀 완료입니다.",
    "sets": "볼륨 50% → 80% → 100% (주간 점진)",
    "cue": "매 훈련 전 90/90 스트레칭 + 클램쉘을 워밍업으로 유지하세요.",
    "how": ["빈 바부터 시작해 고관절 반응을 확인하세요", "매 훈련 전 이완 루틴을 유지하세요"]
}
lunge_return = {
    "name": "런지 전 구간 복귀",
    "why": "고관절 통증이 없으면 훈련 복귀 완료입니다.",
    "sets": "볼륨 50% → 80% → 100% (주간 점진)",
    "cue": "매 훈련 전 이완 루틴을 워밍업으로 유지하세요.",
    "how": ["맨몸 → 덤벨 → 바벨 순으로 점진하세요", "매 훈련 전 이완 루틴을 유지하세요"]
}
deadlift_return = {
    "name": "데드리프트 전 구간 복귀",
    "why": "고관절 통증이 없으면 훈련 복귀 완료입니다.",
    "sets": "볼륨 50% → 80% → 100% (주간 점진)",
    "cue": "매 훈련 전 이완 루틴을 워밍업으로 유지하세요.",
    "how": ["RDL → 박스 데드 → 풀 데드 순으로 점진하세요", "매 훈련 전 이완 루틴을 유지하세요"]
}

# ── 질문/테스트 공통 ─────────────────────────────────────────────
def make_questions(movement_sub):
    return [
        {
            "id": "q1", "text": "통증 위치가 어디인가요?",
            "sub": movement_sub,
            "choices": [
                {"id": "c1", "text": "사타구니 안쪽 (구부릴 때 찝힘)", "next": "cause:cause-a"},
                {"id": "c2", "text": "고관절 앞쪽 (허벅지 위 당김)", "next": "cause:cause-b"},
                {"id": "c3", "text": "엉덩이 바깥쪽 또는 뒤쪽", "next": "cause:cause-c"},
                {"id": "c4", "text": "쉬는 중에도 욱신거린다", "next": "danger"}
            ]
        }
    ]

def make_questions_deadlift():
    return [
        {
            "id": "q1", "text": "통증 위치가 어디인가요?",
            "sub": "엉덩이 아래·사타구니·고관절 앞쪽 중 어느 쪽인지 손으로 짚어보세요.",
            "choices": [
                {"id": "c1", "text": "엉덩이 아래 (앉으면 닿는 뼈 주변)", "next": "cause:cause-a"},
                {"id": "c2", "text": "사타구니 안쪽 (셋업 시 찝힘)", "next": "cause:cause-b"},
                {"id": "c3", "text": "고관절 앞쪽 (허벅지 위 당김)", "next": "cause:cause-c"},
                {"id": "c4", "text": "쉬는 중에도 욱신거린다", "next": "danger"}
            ]
        }
    ]

# ── 스쿼트 고관절 ────────────────────────────────────────────────
squat_hip = {
    "id": "hip", "name": "고관절",
    "coming_soon": False,
    "entry_question": "q1",
    "questions": make_questions("손으로 짚어보세요. 사타구니·앞쪽·바깥쪽 중 어느 쪽인지 확인합니다."),
    "tests": [],
    "danger": danger_hip(),
    "causes": [
        cause_fai(squat_return),
        cause_hip_flexor(squat_return),
        cause_glute(squat_return)
    ]
}

# ── 런지 고관절 ──────────────────────────────────────────────────
lunge_hip = {
    "id": "hip", "name": "고관절",
    "coming_soon": False,
    "entry_question": "q1",
    "questions": make_questions("손으로 짚어보세요. 사타구니·앞쪽·바깥쪽 중 어느 쪽인지 확인합니다."),
    "tests": [],
    "danger": danger_hip(),
    "causes": [
        cause_fai(lunge_return),
        cause_hip_flexor(lunge_return),
        cause_glute(lunge_return)
    ]
}

# ── 데드리프트 고관절 (cause-a = 햄스트링 건병증) ────────────────
deadlift_hip = {
    "id": "hip", "name": "고관절",
    "coming_soon": False,
    "entry_question": "q1",
    "questions": make_questions_deadlift(),
    "tests": [],
    "danger": danger_hip(),
    "causes": [
        cause_hamstring_proximal(deadlift_return),
        cause_fai({**deadlift_return, "name": "데드리프트 전 구간 복귀 (임핀지먼트)"}),
        cause_hip_flexor(deadlift_return)
    ]
}
# 데드리프트는 cause-b가 FAI, cause-c가 굴곡근이므로 id 재조정
deadlift_hip["causes"][1]["id"] = "cause-b"
deadlift_hip["causes"][1]["label"] = "원인 B"
deadlift_hip["causes"][2]["id"] = "cause-c"
deadlift_hip["causes"][2]["label"] = "원인 C"

# ── 적용 ────────────────────────────────────────────────────────
updates = {
    "squat.json": squat_hip,
    "lunge.json": lunge_hip,
    "deadlift.json": deadlift_hip
}

for fname, new_hip in updates.items():
    path = f"data/movements/{fname}"
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for i, s in enumerate(data["pain_sites"]):
        if s["id"] == "hip":
            data["pain_sites"][i] = new_hip
            break
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    with open(path, encoding="utf-8") as f:
        check = json.load(f)
    h = next(s for s in check["pain_sites"] if s["id"] == "hip")
    print(f"{fname}: 원인 {len(h['causes'])}개, stages {[len(c['route']['stages']) for c in h['causes']]}")
