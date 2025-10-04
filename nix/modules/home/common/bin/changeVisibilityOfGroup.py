import sys
import gitlab
from gitlab.base import RESTObject
from gitlab.v4.objects import Group, GroupProject

url = sys.argv[1]
token = sys.argv[2]
gl = gitlab.Gitlab(url, private_token=token)

group = gl.groups.get("project", include_subgroups=True)


# go over every group and subgroup and set the group private
def setGroupPrivate(oldGroup: Group):
    projects = oldGroup.projects.list(all=True)

    for project in projects:
        realProject = gl.projects.get(project.id)
        print("Setting project " + realProject.name + " to private")
        realProject.visibility = "private"
        realProject.save()

    print("All projects in group are now private")

    groups = oldGroup.subgroups.list(all=True)

    if groups:
        for group in groups:
            realGroup = gl.groups.get(group.id)
            setGroupPrivate(realGroup)
        print("Setting group " + oldGroup.name + " to private")
        oldGroup.visibility = "private"
        oldGroup.save()
    else:
        print("Setting group " + oldGroup.name + " to private")
        oldGroup.visibility = "private"
        oldGroup.save()


setGroupPrivate(group)
