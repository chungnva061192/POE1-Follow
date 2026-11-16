#!/bin/bash
# Thành công hoàn toàn -> tự đóng cửa sổ.
# Có lỗi / file bị chương trình khác khoá (git hỏi Y/N) / conflict -> giữ cửa sổ để đọc.

# Git hỏi "... Should I try again? (y/n)" sẽ tự trả lời "n" thay vì treo chờ.
export GIT_ASK_YESNO=false

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

fail() {
    echo ""
    echo "----------❌ LỖI: $1"
    echo ""
    read -p "Press [Enter] to exit..."
    exit 1
}

# Chạy lệnh git, vừa in ra màn hình vừa lưu log để phân loại lỗi.
run_git() {
    git "$@" 2>&1 | tee "$LOG"
    local code=${PIPESTATUS[0]}

    if grep -qiE "Should I try again|Unlink of file|Deletion of directory" "$LOG"; then
        fail "File trong repo đang bị chương trình khác khoá (git hỏi Y/N). Tắt chương trình đó rồi chạy lại."
    fi
    if grep -qE "CONFLICT|Automatic merge failed|needs merge|\[rejected\]|non-fast-forward|fetch first" "$LOG"; then
        fail "Conflict khi 'git $*' (remote có commit mới hoặc merge lỗi) - push CHƯA thành công."
    fi
    if [ "$code" -ne 0 ]; then
        fail "'git $*' thất bại (exit code $code)."
    fi
}

echo "----------➕ Add tất cả file thay đổi..."
echo ""
run_git add .
echo ""

echo "----------📝 Commit..."
echo ""
if git diff --cached --quiet; then
    echo "Không có thay đổi mới để commit, bỏ qua."
else
    run_git commit -m "u"
fi
echo ""

echo "----------📤 Push lên remote..."
echo ""
run_git push
echo ""

echo "----------✅ Hoàn tất!"
exit 0
