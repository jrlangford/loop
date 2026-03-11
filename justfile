skills_dir := env("HOME") / ".claude" / "skills"

skills := "loop-wf-design loop-wf-analyze loop-wf-align loop-define loop-decompose loop-artifacts loop-gates loop-feedback loop-context loop-review loop-reverse loop-audit loop-implement"

# Install all skills as user-level symlinks
install:
    mkdir -p {{ skills_dir }}
    @for skill in {{ skills }}; do \
        ln -sfn "$(pwd)/skills/$skill" "{{ skills_dir }}/$skill"; \
        echo "linked $skill"; \
    done

# Remove all skill symlinks
uninstall:
    @for skill in {{ skills }}; do \
        rm -f "{{ skills_dir }}/$skill"; \
        echo "removed $skill"; \
    done

# List installed loop skills
status:
    @for skill in {{ skills }}; do \
        if [ -L "{{ skills_dir }}/$skill" ]; then \
            echo "✓ $skill → $(readlink {{ skills_dir }}/$skill)"; \
        else \
            echo "✗ $skill (not installed)"; \
        fi; \
    done
